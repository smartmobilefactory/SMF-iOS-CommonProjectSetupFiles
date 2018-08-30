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
if [  -z "$1" ]; then
	projectDir="$scriptBaseFolderPath"
fi

# Check if file smf.properties exits
if [ ! -f "$projectDir/smf.properties" ]; then
	exit 0
fi

# Read smf.properties
while read line; do
	if [[ $line =~ XCODE_VERSION ]]; then
		# Version from smf.properties
		smf_version="${line#XCODE_VERSION=}"

		# Manipulate SMF Xcode version to match Xcode's internal version representation
		check_version="${smf_version//.}"
		if [ "${#check_version}" -lt 4 ]; then
			major_index=$(echo "${smf_version}" | cut -d. -f1)
			if [ "${#major_index}" -eq 1 ]; then
				check_version="0${check_version}"
			fi

			while test "${#check_version}" -lt 4; do
				check_version="${check_version}0"
			done
		fi

		# Check if versions match and send error if necessary
		if [ "${check_version}" -ne "${XCODE_VERSION_ACTUAL}" ]; then
			echo "error: Found Xcode ${smf_version} in smf.properties. Check your Xcode version or update smf.properties"
			exit 1
		fi
	fi
done < "$projectDir/smf.properties"
