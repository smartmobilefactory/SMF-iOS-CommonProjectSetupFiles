#!/bin/bash
# Extracts general code info from a folder:
# - Number of files
# - Amount of empty lines
# - Number of commented lines
# - Number of source code lines

#
#
# Requires Bash version 3 and cloc (github.com/AlDanial/cloc)
#
# Author Hans Seiffert
#
# Last revised 01/19/2017

#
# Constants
#

readonly wrongArgumentsExitCode=1
readonly missingFilesExitCode=2

readonly sourceRootDirectory="Core"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

targetFilename="$1"
metaJSONFolderName="$2"
projectDir="$3"

#
# Methods
#

function display_usage () { 
	echo "This script expects the output filename and foldername of the metaJSON folder as argument. You can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 FILENAME META_JSON_DIR_NAME PROJECT_BASE_DIR FILENAME\n" 
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
	exit $wrongArgumentsExitCode
fi

#
# Logic
#

if which cloc >/dev/null; then
	# Go the "Core" folder
	cd $"$projectDir/$sourceRootDirectory"

	# Generate report
	cloc --vcs=git --quiet --json --out="$projectDir/$metaJSONFolderName/$targetFilename"

	# Go the folder which contains this script
	cd "$scriptBaseFolderPath"
else
	exit $missingFilesExitCode
fi
