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

	# Return comparable version
	echo $display_version
}

# Read smf.properties
while read line; do
	if [[ $line =~ XCODE_VERSION ]]; then
		# Extract version from smf.properties
		specified_xcode_version_string="${line#XCODE_VERSION=}"

		# Retrieve Xcode version and convert it to be comparable
		xcode_version=$(convert_to_comparable_version "$XCODE_VERSION_ACTUAL")

		# Check if versions match and send error if necessary
		if [ "$specified_xcode_version_string" != "$xcode_version" ]; then
			echo "error: Wrong Xcode version: $xcode_version is used but $specified_xcode_version_string specified in smf.properties"
			exit 1
		fi
	fi
done < "$projectDir/smf.properties"
