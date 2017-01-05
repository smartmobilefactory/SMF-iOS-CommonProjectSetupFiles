#!/bin/bash
# Copies the Codebeat configuration files to the projects base folder
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

# Copy the Codebeat files to the projects base folder
cp codebeatignore "$projectDir/.codebeatignore"
cp codebeatsettings "$projectDir/.codebeatsettings"
