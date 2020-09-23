#!/bin/bash
# Copies the DrString configuration to the projects base folder
#
# Author Pierre Rothmaler
#
# Last revised 23/09/2020

#
# Constants
#

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

projectDir="$1"

#
# Check requirements
#

# Check if project directory is provided. If not: Use the scripts base directory.
if [  -z "$1" ]; then
	projectDir="$scriptBaseFolderPath"
fi

#
# Logic
#

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

# Copy the DrString file to the projects base folder
cp "drstring.toml" "$projectDir/.drstring.toml"

# Go to the project folder and run DrString from there
cd "$projectDir"

DRSTRING_EXECUTABLE="$scriptBaseFolderPath/drstring"

if [ -f "$DRSTRING_EXECUTABLE" ]; then
	"$DRSTRING_EXECUTABLE" check --config-file $projectDir/.drstring.toml || true
else
	echo "warning: DrString not installed."
	exit 1
fi