#!/bin/bash
# Extracts meta data from Xcode projects:
# - CocoaPods meta data
#
# Template version 1
#
# File output is eg:
# {
# 	"syntax_version": "1",
# 	"cocapods": {
#		<content of the pods json>
#	}
# }
#
# Requires Bash version 3
#
# Author Hans Seiffert
#
# Last revised 05/01/2017

#
# Constants
#

readonly syntaxVersion=1
readonly syntaxVersionKey="syntax_version"

readonly cocoapodsKey="cocoapods"
readonly podsJSONFilename=".pods.json"

readonly wrongArgumentsExitCode=1

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

targetFilename="$1"
projectDir="$2"
jsonString=""

#
# Methods
#

function display_usage () { 
	echo "This script expects the output filename as argument. You can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 FILENAME PROJECT_BASE_DIR FILENAME\n" 
} 

function append_pods_json () { 
	# Create the temporary json file
	$scriptBaseFolderPath/create-pods-json.sh "$podsJSONFilename" "$projectDir"

	# Check if Podfile exists
	if [ -f "$projectDir/$podsJSONFilename" ]; then
	    podsJSONString=""
	    lineIndex=0
	    while IFS= read -r line; do
	    	if [[ $lineIndex > 0 ]]; then
			    # Get the Pods name
			    podsJSONString+="\n\t"
			fi
			# Get the Pods name
		    podsJSONString+="$line"
		    lineIndex+=1

		done < "$projectDir/$podsJSONFilename"

		jsonString+=",\n\t\"$cocoapodsKey\": $podsJSONString"

		# Delete the temporary pods JSON file
		rm "$projectDir/$podsJSONFilename"
	fi
} 

#
# Check requirements
#

# Check if the filename is provided
if [  -z "$targetFilename" ]; then
   	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if project dir is provided. If not: Use the scripts parent directory
if [  -z "$projectDir" ]; then
	projectDir="$scriptBaseFolderPath"
fi

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

#
# Logic
#

jsonString+="{\n\t\"$syntaxVersionKey\": \"$syntaxVersion\""

append_pods_json

jsonString+="\n}"

# Write the json string to the file
echo -e "$jsonString" > "$projectDir/$targetFilename"
