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
readonly noPRTemplateCopyFlag="--no-pr-template-copy"
readonly noCodebeatFlag="--no-codebeat"
readonly noCodeClimateFlag="--no-codeclimate"
readonly buildConfigurationFlag="--buildconfig"
readonly targetTypeFlag="--targettype"

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

isFramework=false
copyPRTemplate=true
callSwiftlint=true
callCodebeat=true
callCodeClimate=true
projectDir="$(pwd)"
isDebugConfiguration=false

#
# Methods
#

function display_usage () {
	echo "This script performs all common project setup scripts by default. You can optionally pass the projects base directory path as argument. Exceptions can be declared with the flags:"
	echo -e "$noSwiftlintFlag\t\t- Don't run swiftlint"
	echo -e "$noPRTemplateCopyFlag\t- Don't copy the GitHub PR Template file"
	echo -e "$noCodebeatFlag\t\t- Don't copy the default SMF codebeat configuration"
	echo -e "$noCodeClimateFlag\t\t- Don't copy the default SMF Code Climate configuration"
	echo -e "\nUsage:\n$ $0 $noCodebeatFlag"
	echo -e "or:\n$ $0 $noCodebeatFlag /Code/Project/Test"
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
		$targetTypeFlag)
			configName=$(echo "$2" | awk '{print tolower($0)}')
			if [ $configName = "com.apple.product-type.framework" ]; then
				isFramework=true
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
		$noPRTemplateCopyFlag)
			copyPRTemplate=false
			shift
			# break
			;;
		$noCodebeatFlag)
			callCodebeat=false
			shift
			# break
			;;
		$noCodeClimateFlag)
			callCodeClimate=false
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
	./SwiftLint/copy-and-run-swiftlint-config.sh "$projectDir" $isFramework || exit 1;
fi

if [ $callCodebeat = true ]; then
	./Codebeat/copy-codebeat-config.sh "$projectDir" || exit 1;
fi

if [ $callCodeClimate = true ]; then
	./CodeClimate/copy-codeclimate-config.sh "$projectDir" || exit 1;
fi

if [ $copyPRTemplate = true ]; then

	mkdir -p "$projectDir/.github"

	if [ $isFramework = true ]; then
		cp "./Github/PR-Template-Framework.md" "$projectDir/.github/PULL_REQUEST_TEMPLATE.md" || exit 1;
		exit 0
	fi

	cp "./Github/PR-Template-App.md" "$projectDir/.github/PULL_REQUEST_TEMPLATE.md" || exit 1;
fi
