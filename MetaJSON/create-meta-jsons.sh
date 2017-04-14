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
readonly podsJSONFilename="Pods.json"
readonly projectJSONFilename="Project.json"
readonly clocJSONFilename="Cloc.json"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

readonly wrongArgumentsExitCode=1

#
# Variables
#

projectFilename="$1"
projectDir="$2"

#
# Methods
#

function display_usage () { 
	echo "You have to pass the projects filename (name of the Xcode project and workspace files) and can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 HiDrive Users/smf/Code/HiDrive-iOS\n" 
} 

#
# Check requirements
#

# Check if the project and workspace (if used) filename is provided.
if [  -z "$projectFilename" ]; then
	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if project dir is provided. If not: Use the current directory
if [  -z "$projectDir" ]; then
	projectDir="$(pwd)"
fi

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

#
# Logic
#

rm -r "$projectDir/$metaJSONFolderName"
mkdir "$projectDir/$metaJSONFolderName"

./create-pods-json.sh "$podsJSONFilename" "$metaJSONFolderName" "$projectDir"
./create-project-json.sh "$projectJSONFilename" "$metaJSONFolderName" "$projectFilename" "$projectDir"
./create-cloc-json.sh "$clocJSONFilename" "$metaJSONFolderName" "$projectDir"
