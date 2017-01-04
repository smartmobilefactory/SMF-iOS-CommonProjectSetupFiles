#!/bin/bash
# Calls all common project setup scripts. Exceptions can be enabled with flags.
#
# Author Hans Seiffert
#
# Last revised 12/12/2016

#
# Constants
#

readonly noSwiftlintFlag="--no-swiftlint"
readonly noCodebeatFlag="--no-codebeat"
readonly noMetaJSONFlag="--no-metajson"

readonly metaJSONFilename=".meta.json"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

callSwiftlint=true
callCodebeat=true
callMetaJSON=true
projectDir="$(pwd)"

#
# Methods
#

function display_usage () { 
	echo "This script performs all common project setup scripts by default. You can optionally pass the projects base directory path as argument. Exceptions can be declared with the flags:" 
	echo -e "$noSwiftlintFlag" 
	echo -e "$noCodebeatFlag" 
	echo -e "$noMetaJSONFlag" 
	echo -e "\nUsage:\n$ $0 $noMetaJSONFlag\n" 
	echo -e "or:\n$ $0 $noMetaJSONFlag /Code/Project/Test\n" 
} 

#
# Read flags
#

while test $# -gt 0; do
	case "$1" in
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
		$noMetaJSONFlag)
			callMetaJSON=false
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

if [ $callSwiftlint = true ]; then
	./SwiftLint/copy-swiftlint-config.sh "$projectDir"
	./SwiftLint/perform-swiftlint.sh
fi

if [ $callCodebeat = true ]; then
	./Codebeat/copy-codebeat-config.sh "$projectDir"
fi

if [ $callMetaJSON = true ]; then
	./MetaJSON/create-meta-json.sh "$metaJSONFilename" "$projectDir"
fi

exit 0
