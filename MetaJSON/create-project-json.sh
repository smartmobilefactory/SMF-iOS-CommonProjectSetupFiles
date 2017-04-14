#!/bin/bash
#
# Author Hans Seiffert
#
# Last revised 28/01/2017

#
# Constants
#

readonly syntaxVersion=1

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

function prepare_new_json_entry () {
	jsonString+=",\n\t"
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

function append_bitcode_enabled_from_grep () {
	# Use "yes" as bitcode is enabled as default if the key isn't present in the project file
	bitcodeEnabled="yes"
	if $(fgrep -R "ENABLE_BITCODE = [A-Z]*\;" "$xcodeProjectFile" | grep -v "YES\;"); then
		# There are bitcode disabled entries
		if $(fgrep -R "ENABLE_BITCODE = [A-Z]\;"  "$xcodeProjectFile" | grep -v "NO\;"); then
			# There are also bitcode enabled entries. As we can't tell for sure whats used the result is "both"
			bitcodeEnabled="both"
		else
			bitcodeEnabled="no"	
		fi
	fi
	prepare_new_json_entry
	jsonString+="\"bitcode_enabled\": \"$bitcodeEnabled\""
}

function append_idfa_usage_from_grep () {
	idfaUsageStatusString="no"
	if $(fgrep -R advertisingIdentifier "$projectDir" | grep -v BITHockeyManager.h); then
		idfaUsageStatusString="maybe"
	fi
	prepare_new_json_entry
	jsonString+="\"idfa_usage\": \"$idfaUsageStatusString\""
}

function append_swiftlint_usage () {
	prepare_new_json_entry
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
			prepare_new_json_entry
		    jsonString+="\"xcode_version\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (PROGRAMMING_LANGUAGE=(.*)) ]]; then
		    prepare_new_json_entry
			jsonString+="\"programming_language\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (PROGRAMMING_LANGUAGE_VERSION=(.*)) ]]; then
		    prepare_new_json_entry
			jsonString+="\"programming_language_version\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (FASTLANE_BUILD_JOBS_LEVEL=(.*)) ]]; then
			prepare_new_json_entry
		    jsonString+="\"fastlane_build_jobs_level\": \"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (OVERRIDDEN_IDFA_USAGE=(.*)) ]]; then
			override_key_with_value "idfa_usage" "\"${BASH_REMATCH[2]}\""
		elif [[ "$line" =~ (OVERRIDEN_SWIFT_LINT_INTEGRATION=(.*)) ]]; then
			override_key_with_value "swift_lint_integration" "\"${BASH_REMATCH[2]}\""
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

append_bitcode_enabled_from_grep
append_idfa_usage_from_grep
append_swiftlint_usage
append_entries_from_smf_properties

jsonString+="\n}"

# Write the json string to the file
echo -e "$jsonString" > "$projectDir/$metaJSONFolderName/$targetFilename"
