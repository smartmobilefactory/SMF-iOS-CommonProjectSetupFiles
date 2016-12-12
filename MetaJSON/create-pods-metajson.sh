#!/bin/bash
# Extracts meta data from Cocoa Pods projects:
# - CocoaPods version
# - If the acknowledgements are added to the apps settings bundle
# - The name and version of integrated pods (without sub dependencies)
#
# Template version 1
#
# File output is eg:
# {
# 	"syntax": "1",
# 	"version": "1.0.1",
# 	"acknowledgement": false,
# 	"pods": [{
# 		"name": "Alamofire",
# 		"version": "4.1.0"
# 	}, {
# 		"name": "HockeySDK",
# 		"version": "3.8.6"
# 	}
# }
#
# Requires Bash version 3
#
# Author Hans Seiffert
#
# Last revised 12/12/2016

#
# Constants
#

readonly syntaxVersion=1

readonly podfileFilename="Podfile"
readonly podfileLockFilename="Podfile.lock"

readonly dependenciesBeginSectionLine="DEPENDENCIES:"
readonly dependenciesEndSectionLine="SPEC CHECKSUMS:"

readonly versionKey="version"
readonly acknowledgementKey="acknowledgement"
readonly usedPodsKey="pods"
readonly usedPodsNameKey="name"
readonly usedPodsVersionKey="version"

readonly missingFilenameExitCode=1
readonly missingFilesExitCode=2

#
# Variables
#

targetFilename="$1"
podNamesArray[0]=""
jsonString=""

#
# Methods
#

function display_usage () { 
	echo "This script expects the output filename as argument" 
	echo -e "\nUsage:\n$ $0 FILENAME\n" 
} 

function array_contains () { 
    local array="$1[@]"
    local seeking=$2
    local elementIsContained=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            elementIsContained=0
            break
        fi
    done
    return $elementIsContained
}

function append_pods_version_to_json () {
	local versionString="\"$versionKey\": "
	# Read the Podfile.lock and extract the used Cocoa Pods version
	while IFS= read -r line; do
		if [[ "$line" =~ (COCOAPODS: ([0-9.]+)) ]]; then
		    # Get the Pods name
		    versionString+="\"${BASH_REMATCH[2]}\""
		fi
	done  < "$podfileLockFilename"

	jsonString+="$versionString,\n\t"

	return 0
}

function append_acknowledgment_to_json () {
	local acknowledgementString="\"$acknowledgementKey\": "
	# Extract if the acknowledgement plist is used and not commented out
	if grep -q "^\ *[^#]*FileUtils\.cp\_.*-acknowledgements\.plist" "$podfileFilename"; then
 		acknowledgementString+="true"
 	else
 		acknowledgementString+="false"
	fi  
	jsonString+="$acknowledgementString,\n\t"

	return 0
}

function extract_used_pods () {
	local didReachDependenciesSection=false
	local index=0
	# Read the Podfile.lock and extract all direct used pods (not sub pods)
	while IFS= read -r line; do
		if [[ "$line" == $dependenciesBeginSectionLine ]]; then
			# The dependencies section is reached, update the flag to enable the pod name extraction
		   	didReachDependenciesSection=true
		elif [[ "$line" == $dependenciesEndSectionLine ]]; then
		   	# The end of the dependencies section is reached
		   	break
		elif $didReachDependenciesSection && [[ "$line" =~ (- ([^ ]*)( \(|$)) ]]; then
		    # Get the Pods name
		    podNamesArray[$index]=${BASH_REMATCH[2]}
		    # Increment the index
		   	((index++))
		fi
	done  < "$podfileLockFilename"

	return 0
}

function append_used_pods_to_json () {
	extract_used_pods
	local initialPodRead=false
	local index=0
	jsonString+="\"$usedPodsKey\": ["
	# Read the Podfile.lock, extract all direct used pods (not sub pods), their version and create store the information as JSON
	while IFS= read -r line; do
		if [[ "$line" == $dependenciesBeginSectionLine ]]; then
			# The dependencies are is reached. We can break as there will be no more used Pods.
		   	break
		else
		 	# Check if the line represemt a Pods Name and Version and not a Sub-Pods declaration and whether it's a directly added pod (based on the dependencies list)
		 	# eg 		"  - PodName (1.0.0)"
		 	# but not 	"    - "SubPodName (1.0.0)"
		    if [[ "$line" =~ ^[\ ][\ ]-.* ]] && [[ "$line" =~ (-\ (.*) \() ]] && array_contains podNamesArray ${BASH_REMATCH[2]} ; then
	    		# Add the comma if it isn't the first pod entry
	    		if [ $index -ne 0 ]; then
	    			currentPodString=', '
	    		fi
	    		currentPodString+="{\n\t\t"
	    		currentPodString+="\"$usedPodsNameKey\": \"${BASH_REMATCH[2]}\",\n\t\t"
			    # Get the Pods version without the brackets around it
	   			if [[ "$line" =~ \(([0-9.]+)\) ]]; then
				    currentPodString+="\"$usedPodsVersionKey\": \"${BASH_REMATCH[1]}\""
				fi
				currentPodString+='\n\t}'
				((index++))
				jsonString+=$currentPodString
			fi
		fi
	done  < "$podfileLockFilename"

	jsonString+=']\n'

	return 0
}

#
# Check requirements
#

# Check if filename is provided
if [ $# -ne 1 ]; then
   	display_usage
	exit $missingFilenameExitCode
fi

# Check if Podfile exists
if [ ! -f $podfileFilename ]; then
    echo "Error: There is no \"$podfileFilename\" in this folder!"
    exit $missingFilesExitCode
fi

# Check if Podfile.lock exists
if [ ! -f $podfileLockFilename ]; then
    echo "Error: There is no \"$podfileLockFilename\" in this folder! You may have to run \"$ pod install\" first."
    exit $missingFilesExitCode
fi

#
# Logic
#

jsonString+="{\n\t\"syntax\": \"$syntaxVersion\",\n\t"

append_pods_version_to_json
append_acknowledgment_to_json
append_used_pods_to_json

jsonString+="}"

# Write the json string to the file
echo -e $jsonString > $targetFilename

exit 0
