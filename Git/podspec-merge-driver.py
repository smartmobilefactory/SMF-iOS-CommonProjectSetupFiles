#!/usr/bin/env python

import difflib
import sys

def extract_hunks(unified_diff):
	hunks = []
	hunk = []

	for diff in unified_diff:
		# Strip out all whitespace characters
		line = "".join(diff.split())

		if line == '---' or line == '+++':
			continue
		elif line.startswith('@@'):
			if len(hunk) > 0 :
				hunks.append(hunk)
				hunk = []
		else:
			hunk.append(line)

	if len(hunk) > 0:
		hunks.append(hunk)		

	return hunks

def check_for_only_version_change(hunks):
	# If only version is changed, we will have only one hunk
	if len(hunks) > 1:
		return False

	hunk = hunks[0]

	# Make sure the hunk only contains the version change
	for line in hunk:
		if not '.version=' in line:
			return False

	return True


# Create unified diff between ancestor podpsec and other
diff = difflib.unified_diff(open(sys.argv[1]).readlines() ,open(sys.argv[3]).readlines(), n=0)
hunks = extract_hunks(diff)

if check_for_only_version_change(hunks) == True:
	# If only versions are different, we will just take the current version
	sys.exit(0)
else:
	# Other differences require manual merge
	sys.exit(1)
