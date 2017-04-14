#!/bin/bash
#
# Author Hans Seiffert
#
# Last revised 28/01/2017

#
# Constants
#

readonly syntaxVersion=3

readonly smfPropertiesFilename="smf.properties"

readonly syntaxVersionKey="syntax_version"

readonly projectFilenameExtension="xcodeproj"
readonly projectInnerFile="project.pbxproj"
readonly wrongArgumentsExitCode=1
readonly missingFilesExitCode=2

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

targetFilename="$1"
metaJSONFolderName="$2"
projectFilename="$3"
projectDir="$4"
jsonString=""

xcodeProjectFile="$projectDir/$projectFilename.$projectFilenameExtension/$projectInnerFile"

#
# Methods
#

function display_usage () { 
	echo "This script expects the output filename and foldername of the metaJSON folder as argument. You can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 FILENAME META_JSON_DIR_NAME PROJECT_FILENAME PROJECT_BASE_DIR FILENAME\n" 
}


function prepare_new_json_line () {
	jsonString+=",\n\t"
}


function prepare_new_json_array_item () {
	if [[ "$jsonString" =~ "["$ ]]; then 
		jsonString+="\n\t\t"
	else
		jsonString+=",\n\t\t"
	fi
}

function complete_json_array () {
	jsonString+="\n\t]"
}


function prepare_new_json_object_item () {
	if [[ "$jsonString" =~ "{"$ ]]; then 
		jsonString+="\n\t\t"
	else
		jsonString+=",\n\t\t"
	fi
}

function complete_json_object () {
	jsonString+="\n\t}"
}


function prepare_new_json_array_object_item () {
	if [[ "$jsonString" =~ "{"$ ]]; then 
		jsonString+="\n\t\t\t"
	else
		jsonString+=",\n\t\t\t"
	fi
}

function complete_json_array_object () {
	jsonString+="\n\t\t}"
}


function override_key_with_value () {
	key=$1
	value=$2
	if [[ "$jsonString" =~ (\"$key\": ([^,\N\t]*)) ]]; then
		stringToReplace="\"$key\": ${BASH_REMATCH[2]}"
		stringReplacement="\"$key\": $value"
		jsonString=$(echo $jsonString | sed -e "s/$stringToReplace/$stringReplacement/g")
	fi
}

function append_smf_commonprojectsetupfiles () {
	prepare_new_json_line
	jsonString+="\"smf_commonprojectsetupfiles\": {"

	integrated="false"
	while IFS= read -r line; do
		if [[ "$line" =~ (shellScript = .*/setup-common-project-files.sh) ]]; then
			integrated="true"
		fi
	done < "$xcodeProjectFile"

	if [[ "$(cat "$projectDir/.gitmodules")" =~ (path = (.*\s).*url = .*SMF-iOS-CommonProjectSetupFiles\.git) ]]; then
		submodulePath="${BASH_REMATCH[2]}"
		while read line; do
	    	if [[ "$line" =~ (([+-]?(.*) .*"$submodulePath")) ]]; then
				submoduleCommit="${BASH_REMATCH[3]}"
			fi
		done <<< "$(cd $projectDir && git submodule status)"
	fi

	prepare_new_json_object_item
	jsonString+="\"integrated\": $integrated"

	if [[ $submoduleCommit ]]; then
		prepare_new_json_object_item
		jsonString+="\"commit\": \"$submoduleCommit\""
	fi

	complete_json_object
}

function append_bitcode_enabled_from_grep () {
	# Use "yes" as bitcode is enabled as default if the key isn't present in the project file
	bitcodeEnabled="yes"
	if [[ $(fgrep -R "ENABLE_BITCODE = " "$xcodeProjectFile" | grep -v "YES\;") ]]; then
		# There are bitcode disabled entries
		if [[ $(fgrep -R "ENABLE_BITCODE = " "$xcodeProjectFile" | grep -v "NO\;") ]]; then
			# There are also bitcode enabled entries. As we can't tell for sure whats used the result is "both"
			bitcodeEnabled="both"
		else
			bitcodeEnabled="no"	
		fi
	fi
	prepare_new_json_line
	jsonString+="\"bitcode_enabled\": \"$bitcodeEnabled\""
}

function append_ats_exceptions_from_grep () {
	prepare_new_json_line
	jsonString+="\"ats_exceptions\": ["

	while read plistFile; do
		if [[ "$(cat "$plistFile")" =~ (<key>NSAllowsArbitraryLoads<\/key>[^\S]*<true\/>) ]]; then
			exceptionLevel="arbitrary"
		elif [[ "$(cat "$plistFile")" =~ (<key>NSExceptionDomains</key>) ]]; then
			exceptionLevel="domains"
		else
			continue
		fi

		prepare_new_json_array_item
		jsonString+="{"

		prepare_new_json_array_object_item
		jsonString+="\"plist\": \"${plistFile#$projectDir}\""
		prepare_new_json_array_object_item
		jsonString+="\"level\": \"$exceptionLevel\""

		complete_json_array_object
	done <<< "$(find "$projectDir" -type f -name "*.plist" -not -path "$projectDir/Pods/*" -not -path "$projectDir/Carthage/*")"

	complete_json_array
}

function append_idfa_usage_from_grep () {
	prepare_new_json_line
	jsonString+="\"idfa_appearances\": ["	
	idfa_usage="no"

	while read idfaUsage; do
		if [[ $idfaUsage =~ ([^:]*) ]]; then
			idfa_usage="maybe"
			# Get the path of the usage
			usagePath="${BASH_REMATCH[1]}"
			# Remove the project path
			usagePath=${usagePath#$projectDir}
			if [[ $lastFoundPath != $usagePath ]]; then
				prepare_new_json_array_item
				jsonString+="\"$usagePath\""
				lastFoundPath=$usagePath
			fi
		fi
	done <<< "$(fgrep -R advertisingIdentifier "$projectDir" | grep -v BITHockeyManager.h)"

	complete_json_array

	prepare_new_json_line
	jsonString+="\"idfa_usage\": \"$idfa_usage\""
}

function append_swiftlint_usage () {
	prepare_new_json_line
	while IFS= read -r line; do
		if [[ "$line" =~ (shellScript = .*/setup-common-project-files.sh) ]]; then
			if ! [[ "$line" =~ (--no-swiftlint) ]]; then
				jsonString+="\"swift_lint_integration\": \"smf\""
				return
			fi
		fi
	done < "$xcodeProjectFile"

	while IFS= read -r line; do
		if [[ "$line" =~ (shellScript = [^(--(no)-)]*swiftlint(\\n|\;)) ]]; then
			echo "$line"
			if ! [[ "$line" =~ (--no-swiftlint) ]]; then
				jsonString+="\"swift_lint_integration\": \"default\""
				return
			fi
		fi
	done < "$xcodeProjectFile"

	jsonString+="\"swift_lint_integration\": \"none\""
}

function append_entries_from_smf_properties () {
	while IFS= read -r line; do
		if [[ "$line" =~ (XCODE_VERSION=(.*)) ]]; then
			prepare_new_json_line
		    jsonString+="\"xcode_version\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (PROGRAMMING_LANGUAGE=(.*)) ]]; then
		    prepare_new_json_line
			jsonString+="\"programming_language\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (PROGRAMMING_LANGUAGE_VERSION=(.*)) ]]; then
		    prepare_new_json_line
			jsonString+="\"programming_language_version\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (FASTLANE_BUILD_JOBS_LEVEL=(.*)) ]]; then
			prepare_new_json_line
		    jsonString+="\"fastlane_build_jobs_level\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (OVERRIDDEN_IDFA_USAGE=(.*)) ]]; then
			override_key_with_value "idfa_usage" "\"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (OVERRIDEN_SWIFT_LINT_INTEGRATION=(.*)) ]]; then
			override_key_with_value "swift_lint_integration" "\"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (OVERRIDEN_BITCODE_USAGE=(.*)) ]]; then
			override_key_with_value "bitcode_enabled" "\"${BASH_REMATCH[2]}\""
		fi
	done < "$projectDir/$smfPropertiesFilename"
}

#
# Check requirements
#

# Check if filename is provided
if [  -z "$targetFilename" ]; then
   	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if the metaJSON folder name is provided
if [  -z "$metaJSONFolderName" ]; then
   	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if the project and workspace (if used) filename is provided.
if [  -z "$projectFilename" ]; then
   	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if project dir is provided. If not: Use the scripts base directory
if [  -z "$projectDir" ]; then
	projectDir="$scriptBaseFolderPath"
fi

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

#
# Logic
#

jsonString+="{\n\t\"$syntaxVersionKey\": \"$syntaxVersion\""

append_smf_commonprojectsetupfiles
append_bitcode_enabled_from_grep
append_idfa_usage_from_grep
append_ats_exceptions_from_grep
append_swiftlint_usage
append_entries_from_smf_properties

jsonString+="\n}"

# Write the json string to the file
echo -e "$jsonString" > "$projectDir/$metaJSONFolderName/$targetFilename"
