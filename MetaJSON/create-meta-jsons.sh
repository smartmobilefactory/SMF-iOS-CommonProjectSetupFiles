#!/bin/bash
# Triggers the extraction from meta data of Xcode projects:
# - CocoaPods meta data
#
# Author Hans Seiffert
#
# Last revised 05/01/2017

#
# Constants
#

readonly metaJSONFolderName=".MetaJSON"
readonly podsJSONFilename=".pods.json"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

projectDir="$1"

#
# Methods
#

function display_usage () { 
	echo "You can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 PROJECT_BASE_DIR\n" 
} 

#
# Check requirements
#

# Check if project dir is provided. If not: Use the current directory
if [  -z "$projectDir" ]; then
	projectDir="$(pwd)"
fi

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

#
# Logic
#

mkdir "$projectDir/$metaJSONFolderName"

./create-pods-json.sh "$podsJSONFilename" "$metaJSONFolderName" "$projectDir"
