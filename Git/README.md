## Upmerge.sh

The upmerge script is helpful for upmerging branches in the frameworks by automatically merging some files that have conflicts.

It works by using the git merge driver functionality. This allows us to automatically merge some files that normally result in conflicts because they changed on both branches, but we don't actually want to merge the changes.

### Files covered:

- **Podfile.lock**: We always want to take the current version and never want to merge in the one from the branch we are upmerging. The git merge driver here just always picks the current version. This site explains the git merge driver: [https://medium.com/@porteneuve/how-to-make-git-preserve-specific-files-while-merging-18c92343826b](https://medium.com/@porteneuve/how-to-make-git-preserve-specific-files-while-merging-18c92343826b)
- **Podspec**: Here we only want to ignore changes to the version of the podspec. If any other changes were done to the podspec we are upmerging, we have to manually merge them. A custom python script (*podspec-merge-driver.py*) was created to handle detecting the version change.

### Setup
In order to have the merge drivers called for the Podfile.lock and Podspec, the following needs to be added to the *.gitattributes* of the repository.

```
*.podspec merge=podspec-merge-driver
Podfile.lock merge=ours-driver
```

### Usage:

The upmerge script takes two parameters, the branch you are upmerging and the destination branch.

Example: `$ ./upmerge.sh 12.2 13.2`

This upmerges *12.2/master* into *13.2/master*. The script automatically creates a *13.2/upmerge* branch, which you can then push up for a PR.

## podspec-merge-driver.py
This script handles when the podspec has been changed in the branch being upmerged. You don't use this script directly, it is automatically called by git during the merge.

### How it works:
The script takes three arguments as defined by custom merge drivers, see [https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver](https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver). These are the three files: ancestor, current, and other. These can be used to do a three-way merge.

The script just looks at the changes done between the ancestor and other. This tells us what was done to the podspec on the branch being upmerged.

Since we only want to ignore when the version number is changed in the podspec being upmerged, we create a unified diff and check the diff to make sure there are no other changes than the version number.

If we detect any other changes, the script returns a non-zero code and this causes git to consider the file not merged. Manual merging of the podspec is then needed.