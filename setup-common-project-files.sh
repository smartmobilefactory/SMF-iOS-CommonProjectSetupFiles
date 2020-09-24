#!/bin/bash
# Calls all common project setup scripts. Exceptions can be enabled with flags.
#
# Author Hans Seiffert
# Updated Kevin Delord
#
# Last revised 17/09/2020

#
# Constants
#

readonly noSwiftlintFlag="--no-swiftlint"
readonly noPRTemplateCopyFlag="--no-pr-template-copy"
readonly noXcodeCheck="--no-xcodecheck"
readonly targetTypeFlag="--targettype"
readonly breakingInternalFrameworkVersioningFlag="--use-breaking-internal-framework-versioning"
readonly swiftUIFlag="--SwiftUI"

readonly buildConfigurationFlag="--buildconfig" # deprecated
readonly noCodebeatFlag="--no-codebeat" # deprecated
readonly noCodeClimateFlag="--no-codeclimate" # deprecated


readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# Variables
#

isFramework=false
useBreakingInternalFrameworkVersioning=false
copyPRTemplate=true
callSwiftlint=true
checkXcodeVersion=true
projectDir="$(pwd)"
isSwiftUIProject=false

#
# Methods
#

function display_usage () {
	echo "This script performs all common project setup scripts by default. You can optionally pass the projects base directory path as argument. Exceptions can be declared with the flags:"
	echo -e "$noSwiftlintFlag\t\t\t\t- Don't run swiftlint"
	echo -e "$noPRTemplateCopyFlag\t\t\t- Don't copy the GitHub PR Template file"
	echo -e "$breakingInternalFrameworkVersioningFlag\t -Use the \"BreakingInternal framework versioning system\" (only for frameworks)"
	echo -e "$swiftUIFlag\t\t\t\t- Use custom SwiftLint rules for swift ui projects"
	echo -e "\nUsage:\n$ $0 $swiftUIFlag"
	echo -e "or:\n$ $0 $swiftUIFlag /Code/Project/Test"
	exit 1
}

#
# Read flags
#

while test $# -gt 0; do
	case "$1" in
		$buildConfigurationFlag) # Deprecated parameter
			# For legacy and retro-compatibility keep the 'switch-case' and pass through the arguments
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
		$noCodebeatFlag) # Deprecated parameter
			# For legacy and retro-compatibility keep the 'switch-case' and pass through the arguments
			shift
			# break
			;;
		$breakingInternalFrameworkVersioningFlag)
			useBreakingInternalFrameworkVersioning=true
			shift
			# break
			;;
		$swiftUIFlag)
			isSwiftUIProject=true
			shift
			# break
			;;
		$noCodeClimateFlag) # Deprecated parameter
			# For legacy and retro-compatibility keep the 'switch-case' and pass through the arguments
			shift
			# break
			;;
		$noXcodeCheck)
			checkXcodeVersion=false
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
	./SwiftLint/copy-and-run-swiftlint-config.sh "$projectDir" $isFramework $isSwiftUIProject || exit 1;
fi

if [ $isFramework = true ]; then
	./DrString/copy-and-run-DrString-config.sh "$projectDir" || exit 1;
fi

if [ $copyPRTemplate = true ]; then

	mkdir -p "$projectDir/.github"

	if [ $isFramework = true ]; then
		if [ $useBreakingInternalFrameworkVersioning = true ]; then
			cp "./Github/PR-Template-Framework-BreakingInternal-Versioning.md" "$projectDir/.github/PULL_REQUEST_TEMPLATE.md" || exit 1;
		else
			cp "./Github/PR-Template-Framework.md" "$projectDir/.github/PULL_REQUEST_TEMPLATE.md" || exit 1;
		fi
		exit 0
	fi

	cp "./Github/PR-Template-App.md" "$projectDir/.github/PULL_REQUEST_TEMPLATE.md" || exit 1;
fi

if [ $checkXcodeVersion = true ]; then
	./Xcode/check-xcode-version.swift;
fi
