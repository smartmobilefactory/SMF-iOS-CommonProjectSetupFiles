# SMF-iOS-CommonProjectSetupFiles

This Repo contains our common project setup files like .swiftlint.yml, Hockey.swift, Buglife.swift etc.

##SwiftLint

If SwiftLint is or should be used in project you have to install it first (if not done yet). 


### Install SwiftLint
```
$> brew update
$> brew install swiftlint
```

### Update SwiftLint
```
$> brew update
$> brew upgrade swiftlint
```

### Integrate it into the project

**Make sure that `.swiftlint.yml` is added to the gitignore file as the this default SwiftLint configuration file be automtically copied from the repo into the projects base folder.**

Go to the the projects `Build Phases` configuration and add a `New Run Script Phase` called "SwiftLint".

The script should look like:

```
cp Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/.swiftlint.yml ./

if which swiftlint >/dev/null; then
swiftlint
else
echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
fi
```
The default SwiftLint configuration is copied to the base project folder and called from there. 

#### Use an additional project specific SwiftLint config
If you have to modify the SwiftLint configuration for a specific project only you can create a new `.yml` file. By declaring this file during the swiftlint call it will be processed with a higher priority before the default ".swiftlint.yml" configuration is processed. 

The adjusted script should look like this then:

```
cp Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/.swiftlint.yml ./

if which swiftlint >/dev/null; then
swiftlint lint --config .custom_swiftlint.yml
else
echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
fi
```