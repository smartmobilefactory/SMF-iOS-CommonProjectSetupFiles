#!/bin/bash
# Copies the Swiflint configuration to the projects base folder
#
# Author Hans Seiffert
# Updated Kevin Delord
#
# Last revised 17/09/2020

#
# Constants
#

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly temporarySwiftLintConfigFilename=".$(uuidgen)-swiftlint.yml"

#
# Variables
#

projectDir="$1"
isFramework="$2"
swiftUI="$3"

#
# Check requirements
#

# Check if project directory is provided. If not: Use the scripts base directory.
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
			echo "$project_line" >> "$2"
		fi
	done
}

# Merge configuration files together
# Parameters:
# $1: The local/custom config file
# $2: The base file in which the custom config should be merged into
# $3: The output file with the merged configuration. Must not exist (or be empty).
function merge_swiftlint_configuration() {

	read_local_settings "$1"

	# Read the commons SwiftLint configuration file
	while IFS= read -r global_line; do
		# Copy the line first as this allows the script to directly copy the project depened paths if the excluded sections start was found
		echo "$global_line" >> "$3"
		if ([[ "$global_line" =~ (^excluded:) ]] || [[ "$global_line" =~ (^disabled_rules:) ]] || [[ "$global_line" =~ (^opt_in_rules:) ]]) then
			write_local_settings "$global_line" "$3"
		fi
	done < "$2"
}

# Adds disabled rules to disabled section and removes custom rules for the custom rules section
function add_disabled_rules_from_config_file() {
	local config_file_yml=$1
	local base_file=$2
	disabled_pattern="disabled_rules:"
	disabled_flag_1=false
	disabled_flag_2=false
	in_rule=false
	temporarySwiftUILintConfigFilename=".$(uuidgen)-swiftlint-swift-ui.yml"


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
			done < "$config_file_yml"
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
			done < "$config_file_yml"

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

# Copy the normal swiftlint file as temporary one (for later use in this script).
cp "swiftlint.yml" "$temporarySwiftLintConfigFilename"

# Merge the excluded paths of the commons and the project specific configuration
if [ -f "$projectDir/.project-swiftlint.yml" ]; then
	# Merge the project specific configuration.
	merge_swiftlint_configuration "$projectDir/.project-swiftlint.yml" "$temporarySwiftLintConfigFilename" "$temporarySwiftLintConfigFilename.project"
	mv "$temporarySwiftLintConfigFilename.project" "$temporarySwiftLintConfigFilename"
else
	# Copy the project swiftlint configuration template to the repository.
	cp "project-swiftlint.yml" "$projectDir/.project-swiftlint.yml"
fi

if [[ $swiftUI == true ]]; then
	# Merge the SwiftUI specific configuration.
	merge_swiftlint_configuration "swiftlint+swiftUI.yml" "$temporarySwiftLintConfigFilename" "$temporarySwiftLintConfigFilename.swiftUI"
	mv "$temporarySwiftLintConfigFilename.swiftUI" "$temporarySwiftLintConfigFilename"

	# Disabled certain rules listet in swiftlint+swiftUI.yml if this is a swiftUI project
	# TODO: delete custom rules?
	# add_disabled_rules_from_config_file "swiftlint+swiftUI.yml" "$temporarySwiftLintConfigFilename"
fi

if [ $isFramework = true ]; then
	# Merge the Frameworks specific configuration.
	merge_swiftlint_configuration "swiftlint+frameworks.yml" "$temporarySwiftLintConfigFilename" "$temporarySwiftLintConfigFilename.frameworks"
	mv "$temporarySwiftLintConfigFilename.frameworks" "$temporarySwiftLintConfigFilename"
	# TODO: delete custom rules?
	# add_disabled_rules_from_config_file "swiftlint+frameworks.yml" "$temporarySwiftLintConfigFilename"
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
