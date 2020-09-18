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
readonly reportFile=".swiftlint-rules-report.txt"
readonly regexFirstOccurenceRuleName="([A-Za-z_]+).*"
readonly regexEnabledRuleInReport="([A-Za-z_]+)[ ]+(no|yes)[ ]+(no|yes)[ ]+(no|yes)"

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
# Global Arrays
#

# Contains the lines of a read file
declare -a local_lines
# Contains a list of disabled rules (strings)
declare -a all_disabled_rules

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
			# If any, remove the prefix for commenting out disabled rules.
			prefix="# \[Disabled Custom Rule\] "
			line="${line/#$prefix}"
			# AND IF the action is to "match and store the rule" it into an array.
			if [[ $line =~ $regexFirstOccurenceRuleName ]]; then
				disabled_rule="${BASH_REMATCH[1]}"
				# Apply new format as to better identify the custom rules.
				# The listing of a rule is always "| name_of_rule"
				# Format: { prefix: "| " }
				all_disabled_rules[i]="$disabled_rule"
				((++i))
			fi
		fi
	done
}

# An error message occurs when a custom rule is disabled but its declaration within the 'disbaled_rules'
# section is still active. This function comments out the rule declaration declaration.
# Parameters:
# $1: The base configuration file to comment out the disabled custom rules from.
function remove_disabled_rules_from_report() {

	# Create output file
	outputFile="$1.clean"
	touch "$outputFile"

	# Parse the source file and comment out the disabled custom rules
	while IFS= read -r line; do
		if [[ $line =~ $regexFirstOccurenceRuleName ]]; then
			rule_name="${BASH_REMATCH[1]}"
			# If the current line contains a disabled rule declaration then remove it from the report
			if [[ ! " ${all_disabled_rules[@]} " =~ " ${rule_name} " ]]; then
				echo "$line" >> "$outputFile"
			else
				echo "Disabled rule? $line"
			fi
		else
			# It is not a rule but an decorative element of the report
			echo "$line" >> "$outputFile"
		fi
	done < "$1"

	# Replace the source file by the new output file
	mv "$outputFile" "$1"
}

function remove_enabled_rules_from_report() {

	# Create output file
	outputFile="$1.clean"
	touch "$outputFile"

	# Parse the source file and comment out the disabled custom rules
	while IFS= read -r line; do
		# Create a preformated string to better work with REGEX in bash... (remove '|')
		preformated_line="${line//|/ }"
		if [[ $preformated_line =~ $regexEnabledRuleInReport ]]; then
			is_rule_enabled="${BASH_REMATCH[4]}"
			if [[ $is_rule_enabled == "yes" ]]; then
				# If the rule is enabled in the swiftlint config, remove it from the report.
				echo "[Enabled Rule]: ${BASH_REMATCH[1]}"
			else
				echo "$line" >> "$outputFile"
			fi
		else
			# It is not a rule but an decorative element of the report
			echo "$line" >> "$outputFile"
		fi
	done < "$1"

	# Replace the source file by the new output file
	mv "$outputFile" "$1"
}

function extract_disabled_rules() {

	# Read and cache the source file
	read_local_settings "$1"

	# Extract a list of all disabled rules
	while IFS= read -r line; do
		if ([[ "$line" =~ (^disabled_rules:) ]]) then
			extract_values_from_section "$line"
		fi
	done < "$1"
}

#
# Logic
#

# Go the folder which contains this script
# cd "$scriptBaseFolderPath"

# Go to the project folder and run swiftlint from there
cd "$projectDir"

# Extract the list of disabled rules
extract_disabled_rules ".swiftlint.yml"

# Get the complete overview of the default swiftlint rules
touch "$reportFile"

SWIFTLINT_EXECUTABLE="$scriptBaseFolderPath/portable_swiftlint/swiftlint"
if [ -f "$SWIFTLINT_EXECUTABLE" ]; then
	$SWIFTLINT_EXECUTABLE rules > $reportFile
elif which swiftlint >/dev/null; then
	echo "found it"
	swiftlint rules > $reportFile
else
	echo "SwiftLint does not exist, please add it to the Alpha target in your Podfile"
	exit 1
fi

if [ -e "$projectDir/Pods/SwiftLint" ]; then
	echo "warning: SwiftLint should not be added as Pod, as it is already located in SMF-iOS-CommonProjectSetupFiles"
fi

# Remove lines containing the disabled rules
remove_disabled_rules_from_report $reportFile

# Remove lines with "enabled in your config: yes"
remove_enabled_rules_from_report $reportFile

# Do something with the report
# cp "$reportFile" "$projectDir/.swiftlint.yml"
