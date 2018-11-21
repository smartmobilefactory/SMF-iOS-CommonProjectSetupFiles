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
readonly temporarySwiftLintConfigFilename=".$(uuidgen)-swiftlint.yml"

#
# Variables
#

projectDir="$1"
isFramework=$2

#
# Check requirements
#

# Check if project dir is provided. If not: Use the scripts base directory.
if [  -z "$1" ]; then
   	projectDir="$scriptBaseFolderPath"
fi

function merge_commons_with_project_excluded_paths () {

	# Create the temporary file which will contain the merge from the commons and the projects swiftlint configuration
	touch "$temporarySwiftLintConfigFilename"

	# Read the commons SwiftLint configuration file
	while IFS= read -r global_line; do
		# Copy the line first as this allows the script to directly copy the project depened paths if the excluded sections start was found
		echo "$global_line" >> "$temporarySwiftLintConfigFilename"
		if [[ "$global_line" =~ (^excluded:) ]]; then
			# Variable which is true if we are in the excluded section
		    local is_in_excluded_section=false

			# Read the project dependend SwiftLint configuration file
		    while IFS= read -r project_line; do
		    	# Determine if we are in the excluded section
				if [[ "$project_line" =~ (^excluded:) ]]; then
					is_in_excluded_section=true
					continue
				elif [[ "$project_line" =~ (^$) ]]; then
					is_in_excluded_section=false
				fi

				# Copy the excluded path line if we are in the excluded section
				if $is_in_excluded_section; then
					echo "$project_line" >> "$temporarySwiftLintConfigFilename"
				fi

			done < "$projectDir/.project-swiftlint.yml"
		fi

	done < "swiftlint.yml"

	return 0
}

#
# Logic
#

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

# Merge the excluded paths of the commons and the project specific configuration
if [ -f "$projectDir/.project-swiftlint.yml" ]; then
    merge_commons_with_project_excluded_paths
else
	# Copy the normal swiftlint file as tempoary one as this file is used later
	cp "swiftlint.yml" "$temporarySwiftLintConfigFilename"
fi

if [ $isFramework = true ]; then
	# Merge with framework config
	temporaryMergedSwiftLintConfigFilename="$temporarySwiftLintConfigFilename.merged"
	cat "$temporarySwiftLintConfigFilename" "swiftlint+frameworks.yml" > "$temporaryMergedSwiftLintConfigFilename"
	mv "$temporaryMergedSwiftLintConfigFilename" "$temporarySwiftLintConfigFilename"
fi

# Copy the Swiftlint file to the projects base folder
cp "$temporarySwiftLintConfigFilename" "$projectDir/.swiftlint.yml"

# Remove the temporary file after it was copied
rm "$temporarySwiftLintConfigFilename"

# Go to the project folder and run swiftlint from there

cd "$projectDir"

if [ -e "$projectDir/Pods/SwiftLint" ]; then
	echo "warning: SwiftLint should not be added as Pod, as it is already located in SMF-iOS-CommonProjectSetupFiles"
fi

SWIFTLINT_EXECUTABLE="$scriptBaseFolderPath/portable_swiftlint/swiftlint"

if [ -f "$SWIFTLINT_EXECUTABLE" ]; then
	"$SWIFTLINT_EXECUTABLE"
elif which swiftlint >/dev/null; then
	swiftlint
else
	echo "SwiftLint does not exist, please add it to the Alpha target in your Podfile"
	exit 1
fi
