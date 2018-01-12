#!/bin/bash
# Copies the Codebeat configuration files to the projects base folder
#
# Author Hans Seiffert
#
# Last revised 12/01/2017

#
# Constants
#

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly temporaryCodebeatIgnoreFilename=".$(uuidgen)-codebeatignore"

#
# Variables
#

projectDir="$1"

#
# Check requirements
#

# Check if project dir is provided. If not: Use the scripts base directory.
if [  -z "$1" ]; then
   	projectDir="$scriptBaseFolderPath"
fi

#
# Logic
#

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

# Merge default codebeatignore file with the project specific one if it exists
if [ -f "$projectDir/.project-codebeatignore" ]; then
    cat "codebeatignore" "$projectDir/.project-codebeatignore" >> "$temporaryCodebeatIgnoreFilename"
else
	# Copy the default codebeatignore file as tempoary one as this file is used later
	cp "codebeatignore" "$temporaryCodebeatIgnoreFilename"
fi

# Copy the codebeatignore file to the projects base folder
cp "$temporaryCodebeatIgnoreFilename" "$projectDir/.codebeatignore"

# Remove the temporary file after it got copied
rm "$temporaryCodebeatIgnoreFilename"

# Copy the Codebeat settings file to the projects base folder
cp codebeatsettings "$projectDir/.codebeatsettings"
