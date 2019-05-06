#!/bin/bash
# Copies the IBLinter configuration to the projects base folder
#
# Author Urs Kahmann

# Check if project dir is provided. If not throw an error and exit
if [  -z "$1" ]; then
    echo "The projects root directory needs to be provieded. Cannot call IBLinter"
    exit 1
fi

projectRootDir="$1"

# Copy iblinter.yml file into projects root directory if not already present
if [ ! -f "$projectRootDir/.iblinter.yml" ]; then
  cp "IBLinter/.iblinter-template.yml" "$projectRootDir/.iblinter.yml"
fi

# add .iblinter.yml file to .gitignore file if not already present
if ! grep -e "# iblinter" "$projectRootDir/.gitignore" > /dev/null; then
  echo "" >> "$projectRootDir/.gitignore"
  echo "# iblinter" >> "$projectRootDir/.gitignore" 
  echo "/.iblinter.yml" >> "$projectRootDir/.gitignore"
fi

cd "$projectRootDir"

# Run the IBLinter
$projectRootDir/Submodules/SMF-iOS-CommonProjectSetupFiles/IBLinter/iblinter lint
