#!/bin/bash
# Updates SMF-iOS-CommonProjectSetupFiles to the latest version on the current branch
# This script should be called from the project's root directory

cd Submodules/SMF-iOS-CommonProjectSetupFiles

if [ "$?" = "0" ]; then
	currentBranch="$(git branch | grep \* | cut -d ' ' -f2)"

	git pull
	git checkout "$currentBranch"
else
	echo "Cannot change directory!" 1>&2
	exit 1
fi
