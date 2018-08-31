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

function convert_smf_version () {
	# Remove punctuations
	specified_xcode_version="${1//.}"

	# Check if version is than 4 characters long
	if [ "${#specified_xcode_version}" -lt 4 ]; then
		# Extract major version
		major_index=$(echo "${specified_xcode_version_string}" | cut -d. -f1)

		# Check if major version is single or double digit and insert leading 0 if necessary
		if [ "${#major_index}" -eq 1 ]; then
			specified_xcode_version="0${specified_xcode_version}"
		fi

		# Fill in trailing Zeros to be comparable with system version
		while test "${#specified_xcode_version}" -lt 4; do
			specified_xcode_version="${specified_xcode_version}0"
		done
	fi

	# Return comparable version
	echo $specified_xcode_version
}

function convert_version_to_applestyle () {
	# Remove leading 0 from xcode version
	local display_version="${1#0}"

	# Reverse string and insert point seperator for major, minor and patch version
	local tmp_reverse=$(echo "${display_version}" | rev)
	tmp_reverse="${tmp_reverse:0:1}.${tmp_reverse:1:1}."$(echo "${tmp_reverse}" | cut -c 3-)
	display_version=$(echo "${tmp_reverse}" | rev)

	# Remove patch version if 0
	local patch_version="${display_version: -1}"
	if [ "$patch_version" -eq 0 ]; then
		display_version=$(echo "${display_version}" | rev | cut -c 3- | rev)
	fi

	# Return converted version
	echo $display_version
}

# Read smf.properties
while read line; do
	if [[ $line =~ XCODE_VERSION ]]; then
		# Extract version from smf.properties
		specified_xcode_version_string="${line#XCODE_VERSION=}"
		# Convert version to be comparable
		specified_xcode_version_string=$(convert_smf_version "$specified_xcode_version_string")

		# Check if versions match and send error if necessary
		if [ "${specified_xcode_version_string}" -ne "${XCODE_VERSION_ACTUAL}" ]; then
			xcode_version=$(convert_version_to_applestyle "$XCODE_VERSION_ACTUAL")
			echo "error: Xcode ${xcode_version} is used but ${line#XCODE_VERSION=} specified in smf.properties"
			exit 1
		fi
	fi
done < "$projectDir/smf.properties"
