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
swiftUI=$3

#
# Check requirements
#

# Check if project dir is provided. If not: Use the scripts base directory.
if [  -z "$1" ]; then
	projectDir="$scriptBaseFolderPath"
fi

# Contains the local SwiftLint settings (.project-swiftlint.yml). Global so we dont read it multiple times.
declare -a local_lines

# File to array keeping newlines.
function read_local_settings() {
	let i=0
	while IFS=$'\n' read -r -a line_data; do
		local_lines[i]="${line_data}"
		((++i))
	done < $1
}

# Write the desired section of extra settings to the temporary file.
function write_local_settings() {
	# Variable which is true if we are in the excluded section
	local is_in_matched_section=false
	
	# Section to look for
	local matched_section=$1
	
	for project_line in "${local_lines[@]}"; do
		# Determine if we are in the excluded section
		if [[ "$project_line" == "$matched_section" ]]; then
			is_in_matched_section=true
			continue
		elif [[ "$project_line" =~ (^$) ]]; then
			is_in_matched_section=false
		fi

		# Copy the excluded path line if we are in the excluded section
		if $is_in_matched_section; then
			echo "$project_line" >> "$temporarySwiftLintConfigFilename"
		fi
	done
}

function merge_commons_with_project_excluded_paths() {

	read_local_settings "$projectDir/.project-swiftlint.yml"

	# Create the temporary file which will contain the merge from the commons and the projects swiftlint configuration
	touch "$temporarySwiftLintConfigFilename"

	# Read the commons SwiftLint configuration file
	while IFS= read -r global_line; do
		# Copy the line first as this allows the script to directly copy the project depened paths if the excluded sections start was found
		echo "$global_line" >> "$temporarySwiftLintConfigFilename"
		if ([[ "$global_line" =~ (^excluded:) ]] || [[ "$global_line" =~ (^disabled_rules:) ]]) then
			write_local_settings "$global_line"
		fi
	done < "swiftlint.yml"

	return 0
}

# Adds disabled rules to diabled section and removes custom rules for the custom rules section
function add_swiftUI_disabled_rules() {
	disabled_pattern="disabled_rules:"
	disabled_flag_1=false
	disabled_flag_2=false
	in_rule=false
	temporarySwiftUILintConfigFilename=".$(uuidgen)-swiftlint-swift-ui.yml"
	local base_file=$1

	touch "$temporarySwiftUILintConfigFilename"

	while IFS= read -r line_1 || [[ -n "$line_1" ]]; do

		if [[ $disabled_flag_1 == true ]]; then

			while IFS= read -r line_2 || [[ -n "$line_2" ]]; do

				if [[ $disabled_flag_2 == true ]]; then
					echo "$line_2" >> "$temporarySwiftUILintConfigFilename"
				fi

				if [[ $line_2 =~ $disabled_pattern ]]; then
					disabled_flag_2=true
				fi
			done < "swiftlint+swiftUI.yml"
			disabled_flag_1=false
		fi

		disabled_flag_2=false

		if [[ $line_1 =~ $disabled_pattern ]]; then
			disabled_flag_1=true
			echo $line_1 >> "$temporarySwiftUILintConfigFilename"
		else
			while IFS= read -r line_2 || [[ -n "$line_2" ]]; do
				if [[ $disabled_flag_2 == true ]]; then
					if [[ $line_1 =~ ${line_2:3} ]]; then
						in_rule=first
					fi
				fi

				if [[ $line_2 =~ $disabled_pattern ]]; then
					disabled_flag_2=true
				fi
			done < "swiftlint+swiftUI.yml"

			if [[ $in_rule == false ]]; then
				echo "$line_1" >> "$temporarySwiftUILintConfigFilename"
			elif [[ $in_rule == first ]]; then
				in_rule=true
			elif [[ ${line_1:3:1} != " " ]]; then
				echo "$line_1" >> "$temporarySwiftUILintConfigFilename"
				in_rule=false
			fi

			if [[ $line_1 =~ $disabled_pattern ]]; then
				disabled_flag_1=true
			fi
		fi

	done < "$base_file"

	cp "$temporarySwiftUILintConfigFilename" "$temporarySwiftLintConfigFilename"
	rm "$temporarySwiftUILintConfigFilename"
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
	
	if [[ $swiftUI == true ]]; then
		add_swiftUI_disabled_rules "$temporarySwiftLintConfigFilename"
	fi
else
	# Disabled certain rules listet in swiftlint+swiftUI.yml if this is a swiftUI project
	if [[ $swiftUI == true ]]; then
		add_swiftUI_disabled_rules "swiftlint.yml"
	else
		# Copy the normal swiftlint file as tempoary one as this file is used later
		cp "swiftlint.yml" "$temporarySwiftLintConfigFilename"
	fi
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
