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

### Integrate it in the project

Go to the the projects `Build Phases` configuration and add a `New Run Script Phase` calles "SwiftLint".

The script should look like:

```
if which swiftlint >/dev/null; then
swiftlint lint --config Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/.swiftlint.yml
else
echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
fi
```