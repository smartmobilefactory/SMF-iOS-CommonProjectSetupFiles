#!/bin/bash
# Creates the metaJSONs and pushes them to the git repo.
#
# Author Hans Seiffert
#
# Last revised 09/01/2017

#
# Constants
#

readonly metaJSONFolderName=".MetaJSON"
readonly commitMessage="Update MetaJSONs"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

readonly wrongArgumentsExitCode=1

#
# Variables
#

branchName="$1"
projectFilename="$2"
projectDir="$3"

#
# Check requirements
#

function display_usage () { 
	echo "This script expects the git branch name and the Xcode project name as argument. You can pass the projects base folder path if needed. Otherwise the scripts parent folder path is used." 
	echo -e "\nUsage:\n$ $0 GIT_BRANCH_NAME XCODE_PROJECT_NAME\n" 
} 

# Check if the branch name was provided
if [ -z "$branchName" ]; then
	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if the project and workspace (if used) filename is provided.
if [  -z "$projectFilename" ]; then
   	display_usage
	exit $wrongArgumentsExitCode
fi

# Check if project dir is provided. If not: Use the current directory
if [  -z "$projectDir" ]; then
	projectDir="$(pwd)"
fi

# Go the projects base folder
cd "$projectDir"

#
# Logic
#

git fetch
git checkout -B "$branchName"
git submodule update

if [ "$?" = "0" ]; then
	
	"$scriptBaseFolderPath/create-meta-jsons.sh" "$projectFilename" "$projectDir"

	git add "$metaJSONFolderName"
	git commit -m "$commitMessage"
	git push origin "$branchName"
else
	echo "Failed to commit and push to the git repo" 1>&2
	exit 1
fi
