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


readonly wrongArgumentsExitCode=1
readonly missingFilesExitCode=2

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

targetFilename="$1"
metaJSONFolderName="$2"
projectDir="$3"
jsonString=""

#
# Methods
#

function display_usage () { 
	echo "This script expects the output filename and foldername of the metaJSON folder as argument. You can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 FILENAME META_JSON_DIR_NAME PROJECT_BASE_DIR FILENAME\n" 
} 

function prepare_new_json_entry () {
	jsonString+=",\n\t"
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

append_entries_from_smf_properties

jsonString+="\n}"

# Write the json string to the file
echo -e "$jsonString" > "$projectDir/$metaJSONFolderName/$targetFilename"
