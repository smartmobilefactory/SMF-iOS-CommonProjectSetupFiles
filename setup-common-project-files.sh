#!/bin/bash
# Calls all common project setup scripts. Exceptions can be enabled with flags.
#
# Author Hans Seiffert
#
# Last revised 05/01/2017

#
# Constants
#

readonly noSwiftlintFlag="--no-swiftlint"
readonly noCodebeatFlag="--no-codebeat"
readonly buildConfigurationFlag="--buildconfig"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

callSwiftlint=true
callCodebeat=true
projectDir="$(pwd)"
isDebugConfiguration=false

#
# Methods
#

function display_usage () { 
	echo "This script performs all common project setup scripts by default. You can optionally pass the projects base directory path as argument. Exceptions can be declared with the flags:" 
	echo -e "$noSwiftlintFlag" 
	echo -e "$noCodebeatFlag" 
	echo -e "\nUsage:\n$ $0 $noCodebeatFlag\n" 
	echo -e "or:\n$ $0 $noCodebeatFlag /Code/Project/Test\n" 
} 

#
# Read flags
#

while test $# -gt 0; do
	case "$1" in
		$buildConfigurationFlag)
			configName=$(echo "$2" | awk '{print tolower($0)}')
			if [ $configName = "debug" ]; then
				isDebugConfiguration=true
			fi
			shift
			shift
			# break
			;;
		$noSwiftlintFlag)
			callSwiftlint=false
			shift
			# break
			;;
		$noCodebeatFlag)
			callCodebeat=false
			shift
			# break
			;;
		-*)
			display_usage
			shift
			;;
		*)
			# This is the project directory
			projectDir="$1"
			shift
			;;
	esac
done

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

#
# Call scripts
#

#echo "$callSwiftlint - $isDebugConfiguration"
#exit 1
if [ $callSwiftlint = true ] && [ $isDebugConfiguration = true ]; then
	./SwiftLint/copy-and-run-swiftlint-config.sh "$projectDir" || exit 1;
fi

if [ $callCodebeat = true ]; then
	./Codebeat/copy-codebeat-config.sh "$projectDir" || exit 1;
fi
