#!/bin/bash
# Updates SMF-iOS-CommonProjectSetupFiles to the latest version on the current branch
# This script should be called from the project's root directory

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

commonProjectSetupFilesDirectory="$1"

#
# Check requirements
#

# Check if the directory is provided. If not: Use the scripts parent directory
if [  -z "$projectDir" ]; then
	commonProjectSetupFilesDirectory="$scriptBaseFolderPath"
fi

#
# Logic
#

cd $commonProjectSetupFilesDirectory

if [ "$?" = "0" ]; then
	currentBranch="$(git branch | grep \* | cut -d ' ' -f2)"

	git pull
	git checkout "$currentBranch"
else
	echo "Cannot change directory!" 1>&2
	exit 1
fi
