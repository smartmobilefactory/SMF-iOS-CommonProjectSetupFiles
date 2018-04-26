#!/bin/bash
# Copies the Code Climate configuration files to the projects base folder
#
# Author Hans Seiffert
#
# Last revised 26/04/2018

#
# Constants
#

readonly scriptBaseFolderPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly temporaryCodeClimateConfigFilename=".$(uuidgen)-codeclimate.yml"

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

function merge_commons_with_project_excluded_patterns () {

	# Create the temporary file which will contain the merge from the commons and the projects Code Climate configuration
	touch "$temporaryCodeClimateConfigFilename"

	# Read the commons Code Climate configuration file
	while IFS= read -r global_line; do
		# Copy the line first as this allows the script to directly copy the project depened paths if the excluded sections start was found
		echo "$global_line" >> "$temporaryCodeClimateConfigFilename"
		if [[ "$global_line" =~ (^exclude_patterns:) ]]; then
			# Variable which is true if we are in the excluded patterns section
		    local is_in_excluded_section=false

			# Read the project dependend Code Climate configuration file
		    while IFS= read -r project_line; do
		    	# Determine if we are in the excluded patterns section
				if [[ "$project_line" =~ (^exclude_patterns:) ]]; then
					is_in_excluded_section=true
					continue
				elif [[ "$project_line" =~ (^$) ]]; then
					is_in_excluded_section=false
				fi

				# Copy the excluded path line if we are in the excluded patterns section
				if $is_in_excluded_section; then
					echo "$project_line" >> "$temporaryCodeClimateConfigFilename"
				fi

			done < "$projectDir/.project-codeclimate.yml"
		fi

	done < "codeclimate.yml"

	return 0
}

#
# Logic
#

# Go the folder which contains this script
cd "$scriptBaseFolderPath"

# Merge the excluded paths of the commons and the project specific configuration
if [ -f "$projectDir/.project-codeclimate.yml" ]; then
    merge_commons_with_project_excluded_patterns
else
	# Copy the normal Code Climate file as tempoary one as this file is used later
	cp "codeclimate.yml" "$temporaryCodeClimateConfigFilename" 
fi

# Copy the Code Climate file to the projects base folder
cp "$temporaryCodeClimateConfigFilename" "$projectDir/.codeclimate.yml"

# Remove the temporary file after it was copied
rm "$temporaryCodeClimateConfigFilename"
