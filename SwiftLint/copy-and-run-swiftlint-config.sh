#!/bin/bash
# Copies the Swiflint configuration to the projects base folder
#
# Author Hans Seiffert
#
# Last revised 05/01/2017

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

# Check if project dir is provided. If not: Use the scripts base directory.
if [  -z $1 ]; then
   	projectDir="$scriptBaseFolderPath"
fi

#
# Logic
#

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

# Copy the Swiftlint file to the projects base folder
cp swiftlint.yml "$projectDir/.swiftlint.yml"

# Go to the project folder and run swiftlint from there

cd "$projectDir"

SWIFTLINT_EXECUTABLE="$projectDir/Pods/SwiftLint/swiftlint"

if [ -f "$SWIFTLINT_EXECUTABLE" ]; then
	"$SWIFTLINT_EXECUTABLE"
elif which swiftlint >/dev/null; then
	swiftlint
else
	echo "SwiftLint does not exist, please add it to the Alpha target in your Podfile"
	exit 1
fi
