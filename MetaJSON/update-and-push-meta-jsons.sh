#!/bin/bash
# Creates the metaJSONs and pushes them to the git repo.
#
# Author Hans Seiffert
#
# Last revised 09/01/2017

#
# Constants
#

readonly commitMessage="Update MetaJSONs"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

projectDir="$1"

#
# Check requirements
#

# Check if project dir is provided. If not: Use the current directory
if [  -z "$projectDir" ]; then
	projectDir="$(pwd)"
fi

# Go the projects base folder
cd "$projectDir"

#
# Logic
#

"$scriptBaseFolderPath/create-meta-jsons.sh" "$projectDir"

if [ "$?" = "0" ]; then
	git pull
	git add .
	git commit -m "$commitMessage"
	git push
else
	echo "Failed to commit and push to the git repo" 1>&2
	exit 1
fi
