#!/bin/bash
# Compares the currently used Xcode version to build the project with the version recorded in smf.properties
#
# Author Thanh Duc Do
#
# Last revised 30/08/2018

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
if [ -z "$1" ]; then
	projectDir="$scriptBaseFolderPath"
fi

# Check if file smf.properties exits. If not: exit script
if [ ! -f "$projectDir/smf.properties" ]; then
	exit 0
fi

#
# Functions
#

function convert_to_comparable_version () {
	# Remove leading 0 from xcode version
	local display_version="${1#0}"

	# Reverse string and insert dot seperator for major, minor and patch version
	local tmp_reverse=$(echo "$display_version" | rev)
	tmp_reverse="${tmp_reverse:0:1}.${tmp_reverse:1:1}."$(echo "$tmp_reverse" | cut -c 3-)
	display_version=$(echo "$tmp_reverse" | rev)

	# Remove patch version if 0
	local patch_version="${display_version: -1}"
	if [ "$patch_version" -eq 0 ]; then
		display_version=$(echo "$display_version" | rev | cut -c 3- | rev)
	fi

	# Return version
	echo $display_version
}

function add_patch_version_if_necessary () {
	# Count occurrences of dots to determine if patch version is included
	local dot_count=$(echo "$1" | grep -o "\." | wc -l)

	# Add patch version 0 if necessary
	if [ "$dot_count" -eq 1 ]; then
		echo "$1.0"
	else
		echo "$1"
	fi
}

# Read smf.properties
while read line; do
	if [[ $line =~ XCODE_VERSION ]]; then
		# Retrieve specified version from smf.properties and comparable version
		specified_xcode_version_string="${line#XCODE_VERSION=}"
		specified_xcode_version_comparable=$(add_patch_version_if_necessary "$specified_xcode_version_string")

		# Retrieve Xcode version and comparable Xcode version
		xcode_version=$(convert_to_comparable_version "$XCODE_VERSION_ACTUAL")
		xcode_version_comparable=$(add_patch_version_if_necessary "$xcode_version")

		# Check if versions match and send error if necessary
		if [ "$specified_xcode_version_comparable" != "$xcode_version_comparable" ]; then
			echo "error: Wrong Xcode version: $xcode_version is used but $specified_xcode_version_string specified in smf.properties"
			exit 1
		fi
	fi
done < "$projectDir/smf.properties"
