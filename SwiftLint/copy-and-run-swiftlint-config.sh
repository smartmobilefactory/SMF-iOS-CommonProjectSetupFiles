#!/bin/bash
# Copies the Swiftlint configuration to the projects base folder
#
# Author Hans Seiffert
# Updated Kevin Delord
#
# Last revised 17/09/2020

#
# Constants
#

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly tmpFile=".$(uuidgen)-swiftlint.yml"
readonly regexFirstOccurenceRuleName="([A-Za-z_]+).*"

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

#
# Global Arrays
#

# Contains the lines of a read file
declare -a local_lines
# Contains a list of disabled rules (strings)
declare -a all_disabled_rules
# Contains a list of the disabled CUSTOM rules only (strings)
declare -a all_disabled_custom_rules

# File to array keeping newlines.
function read_local_settings() {
	unset local_lines
	let i=0
	while IFS=$'\n' read -r -a line_data; do
		local_lines[i]="${line_data}"
		((++i))
	done < $1
}

# Extract the values from a YML section.
# Parameters:
# $1: String representing the section to find adn extract the values from
# $2: Action parameter: either "--write-to-file" or "--match-and-store-rule"
# $3: Output file to write the data to. Only used if "--write-to-file" is provided.
function extract_values_from_section() {
	# Variable which is true if we are in the excluded section
	local is_in_matched_section=false

	# Section to look for
	local matched_section=$1

	# Prepare storage
	unset all_disabled_rules
	let i=0

	for line in "${local_lines[@]}"; do

		# Determine if we are in the excluded section
		if [[ "$line" == "$matched_section" ]]; then
			is_in_matched_section=true
			continue
		elif [[ "$line" =~ (^$) ]]; then
			is_in_matched_section=false
		fi

		# IF the current line is within the matched section
		if $is_in_matched_section; then
			if [[ "$2" == "--write-to-file" ]]; then
				# AND IF the action is to "write to an output file" THEN echo the line
				echo "$line" >> "$3"

			elif [[ "$2" == "--match-and-store-rule" ]]; then
				# OR IF the action is to "match and store the rule" it into an array.
				if [[ $line =~ $regexFirstOccurenceRuleName ]]; then
					disabled_rule="${BASH_REMATCH[1]}"
					# Apply new format as to better identify the custom rules.
					# The declaration of a custom rule is always "  name_of_rule:"
					# Format: { prefix: 2 whitespaces, sufix: ':' }
					all_disabled_rules[i]="  $disabled_rule:"
					((++i))
				fi
			fi
		fi
	done
}

# Merge swiftlint configuration files together
# Parameters:
# $1: The local/custom config file
# $2: The base file in which the custom config should be merged into
# $3: The action to do when extracting the rules. See parameters of the function "extract_values_from_section" for more info.
# $4: The output file with the merged configuration. Must not exist (or be empty).
function merge_swiftlint_configuration() {

	read_local_settings "$1"

	# Read the commons SwiftLint configuration file based on the cached file (`read_local_settings`)
	while IFS= read -r global_line; do
		# Copy the line first as this allows the script to directly copy the project depened paths if the excluded sections start was found
		echo "$global_line" >> "$4"
		if ([[ "$global_line" =~ (^excluded:) ]] || [[ "$global_line" =~ (^disabled_rules:) ]] || [[ "$global_line" =~ (^opt_in_rules:) ]]) then
			extract_values_from_section "$global_line" "$3" "$4"
		fi
	done < "$2"
}

# An error message occurs when a custom rule is disabled but its declaration within the 'disbaled_rules'
# section is still active. This function comments out the rule declaration declaration.
# Parameters:
# $1: The base configuration file to comment out the disabled custom rules from.
function disable_custom_rules_declaration() {

	# Create output file
	outputFile="$1.clean"
	touch "$outputFile"

	# Parse the source file and comment out the disabled custom rules
	while IFS= read -r line; do
		# If the current line contains the custom rule declaration (with the special formating)
		# Then comment it out with a clear message.
		# Format: { prefix: 2 whitespaces + '-' + 1 whitespace }
		if [[ "${all_disabled_custom_rules[@]}" =~ $line ]]; then
			echo "# [Disabled Custom Rule] $line" >> "$outputFile"
		else
			echo "$line" >> "$outputFile"
		fi
	done < "$1"

	# Replace the source file by the new output file
	mv "$outputFile" "$1"
}

# Comment out the disabled custom rules from the configuration file.
# Without this logic the rule would still work even though it is listed in the section "disabled_rules:".
# Parameters:
# $1: The base configuration file to comment out the disabled custom rules from.
function disable_custom_rules_configuration() {

	# Read and cache the source file
	read_local_settings "$1"

	# Extract a list of all disabled rules based on the cached file (`read_local_settings`)
	while IFS= read -r line; do
		if ([[ "$line" =~ (^disabled_rules:) ]]) then
			extract_values_from_section "$line" "--match-and-store-rule"
		fi
	done < "$1"

	# Create output file
	outputFile="$1.clean"
	touch "$outputFile"
	unset all_disabled_custom_rules
	let i=0

	# Parse the source file and comment out disabled custom rules
	line_in_disabled_rule=false
	while IFS= read -r line; do
		# If the current line contains the custom rule declaration (with the special formating) then toggle the boolean.
		# Format: { prefix: 2 whitespaces, sufix: ':' }
		if [[ "${all_disabled_rules[@]}" =~ $line ]]; then
			line_in_disabled_rule=true
			echo "# [Disabled Custom Rule] $line" >> "$outputFile"
			# Retain the name of the custom and disabled rules.
			if [[ $line =~ $regexFirstOccurenceRuleName ]]; then
				disabled_custom_rule="${BASH_REMATCH[1]}"
				# Extract the raw name of the rule and apply the format of the rule declaration
				# to match the content in the 'disabled_rules' section.
				# Format: { prefix: 2 whitespaces + '-' + 1 whitespace }
				all_disabled_custom_rules[i]="  - $disabled_custom_rule"
				((++i))
			fi

		# If the current line is within a disabled custom rule then add a prefix to comment it out.
		# This way we will stay transparent and have an eye on disabled rules, rathen than having them disappearing.
		elif [[ "$line_in_disabled_rule" = true ]]; then
			# The current line is not in the rule declaration anymore WHEN it does not start with 3 whitespaces;
			# in this case the current line is a new rule declaration (that is not disabled).
			if [[ ! $line == "   "* ]]; then
				echo "$line" >> "$outputFile"
				line_in_disabled_rule=false
			else
				echo "# [Disabled Custom Rule] $line" >> "$outputFile"
			fi

		# Finally, if the line is not within a rule, simply write to the output file
		elif [[ "$line_in_disabled_rule" = false ]]; then
			echo "$line" >> "$outputFile"
		fi
	done < "$1"

	# Replace the source file by the new output file
	mv "$outputFile" "$1"
}

#
# Logic
#

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

# Copy the normal swiftlint file as temporary one (for later use in this script).
cp "swiftlint.yml" "$tmpFile"

# Merge the excluded paths of the commons and the project specific configuration
if [ -f "$projectDir/.project-swiftlint.yml" ]; then
	# Merge the project specific configuration.
	merge_swiftlint_configuration "$projectDir/.project-swiftlint.yml" "$tmpFile" "--write-to-file" "$tmpFile.project"
	mv "$tmpFile.project" "$tmpFile"
else
	# Copy the project swiftlint configuration template to the repository.
	cp "project-swiftlint.yml" "$projectDir/.project-swiftlint.yml"
fi

if [[ $swiftUI = true ]]; then
	# Merge the SwiftUI specific configuration.
	merge_swiftlint_configuration "swiftlint+swiftUI.yml" "$tmpFile" "--write-to-file" "$tmpFile.swiftUI"
	mv "$tmpFile.swiftUI" "$tmpFile"
fi

if [ $isFramework = true ]; then
	# Merge the Frameworks specific configuration.
	merge_swiftlint_configuration "swiftlint+frameworks.yml" "$tmpFile" "--write-to-file" "$tmpFile.frameworks"
	mv "$tmpFile.frameworks" "$tmpFile"

	# Find the unit test directory
	if [ -e "$projectDir/Unit-Tests" ]; then
		unitTestDir="$projectDir/Unit-Tests"
	elif [ -e "$projectDir/UnitTests" ]; then
		unitTestDir="$projectDir/UnitTests"
	fi

	if [ -e $unitTestDir ]; then
		if [ -f "$unitTestDir/.project-swiftlint.yml" ]; then
			# Deals with .project-swiftlint.yml for unit tests
			rm "$unitTestDir/.swiftlint.yml"
			merge_swiftlint_configuration "$unitTestDir/.project-swiftlint.yml" "swiftlint+frameworksUnitTest.yml" "--write-to-file" "$unitTestDir/.swiftlint.yml"
		else
			cp "swiftlint+frameworksUnitTest.yml" "$unitTestDir/.swiftlint.yml"
		fi
	fi
fi

# Comment out the disabled custom rules from the configuration file
# This way we keep the configuration clear and the process transparent (what we have / what is disabled)
disable_custom_rules_configuration "$tmpFile"
disable_custom_rules_declaration "$tmpFile"

# Copy the Swiftlint file to the projects base folder
cp "$tmpFile" "$projectDir/.swiftlint.yml"

# Remove the temporary file after it was copied
rm "$tmpFile"

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
