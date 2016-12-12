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
readonly noMetaJSONFlag="--no-metajson"

#
# Constants
#

call_swiftlint=true
call_metaJSON=true

#
# Methods
#

function display_usage () { 
	echo "This script performs all common project setup scripts by default. Exceptions can be declared with the flags:" 
	echo -e "\n$noSwiftlintFlag" 
	echo -e "\n$noMetaJSONFlag" 
	echo -e "\nUsage:\n$ $0 $noMetaJSONFlag\n" 
} 

# Go the folder which contains this script
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Read flags
#

while test $# -gt 0; do
	case "$1" in
		$noSwiftlintFlag)
			call_swiftlint=false
			shift
			# break
			;;
		$noMetaJSONFlag)
			call_metaJSON=false
			shift
			# break
			;;
		*)
			echo "unkown option $1"
			shift
			;;
	esac
done

#
# Call scripts
#

if [ $call_swiftlint = true ]; then
	sh ./SwiftLint/copy-swiftlint-config.sh
fi

if [ $call_metaJSON = true ]; then
	sh ./MetaJSON/create-pods-metajson.sh Pods.json
fi

exit 0
