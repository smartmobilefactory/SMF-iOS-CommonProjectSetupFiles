#!/bin/bash
# Performs the Swiftlint lint
#
# Author Hans Seiffert
#
# Last revised 04/01/2017

if which swiftlint >/dev/null; then
	swiftlint
	exit 0
else
	echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
	exit 1
fi

