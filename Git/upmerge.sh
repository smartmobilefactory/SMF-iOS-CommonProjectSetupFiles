#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Wrong number of parameters, should be <source branch> <destination branch>. Example: ./upmerge.sh 12.2 13.2"
    exit 1
fi

if [[ -n $(git status -s) ]]; then
 	echo "Git tree is dirty, please commit changes before upmerging"
 	exit 1
fi

git checkout origin/$2/master

git checkout -b $2/upmerge

git config merge.ours-driver.driver true
git config merge.podspec-merge-driver.driver "./Submodules/SMF-iOS-CommonProjectSetupFiles/Git/podspec-merge-driver.py %O %A %B"

git merge origin/$1/master --no-edit

git config --unset merge.ours-driver.driver
git config --unset merge.podspec-merge-driver
