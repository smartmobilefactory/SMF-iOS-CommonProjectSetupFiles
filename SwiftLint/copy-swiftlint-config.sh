#!/bin/bash
# Copies the swiflint configuration to the projects base folder
#
# Author Hans Seiffert
#
# Last revised 12/12/2016

# Go the folder which contains this script
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cp swiftlint.yml ../.swiftlint.yml

exit 0