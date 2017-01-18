# SMF-iOS-CommonProjectSetupFiles

This Repo contains our common project setup files.

Helpers which can be added manually to the Xcode project which should be used:

- [HockeySDK.swift](#HockeyApp-SDK)
- [BuglifeSDK.swift](#Buglife-SDK)

Scripts which should be called during the build phase:

- [SwiftLint](##SwiftLint)
- [Codebeat](##Codebeat)

Scripts which are used manually or by the CI:

- [MetaJSON](##MetaJSON)

### Setup

Go to the the projects `Build Phases` configuration, add a `New Run Script Phase` called "SMF-iOS-CommonProjectSetupFiles" and place it below `Compile Sources`.

The script should look like:

```
Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh
```

This will copy the Codebeat configuration files, copy the SwiftLint configuration and run SwiftLint. In case either of them shouldn't be used in the project a flag can be used to opt out (see the readme below).

# Documentation

## Helper classes

### HockeyApp-SDK

This repo contains the `HockeySDK` helper struct which takes care of the default HockeyApp SDK setup. The SDK will be initialized with the App ID and the Crash Manager started.

#### Integrate the HockeyApp SDK
To use the HockeySDK.swift helper struct you have to manually add the HockeyApp SDK to your project first. Use the preferred way to do this - at this time it's [CocoaPods](https://cocoapods.org).

#### Add the HockeyApp App ID to the info plists
The helper struct will automatically read the App IDs from the info plists. It's mandatory to add these with the key `HockeyAppId` to all info plists in the project:

```
<key>HockeyAppId</key>
<string>ABCDE...</string>
```

#### Add the HockeySDK.swift file to the project

Once the SDK is properly integrated and the App IDs set you have to add the `HockeySDK.swift` file to the Xcode project:

```
Project navigator > Submodules > Add files to "SMF-iOS-CommonProjectSetupFiles" > Choose the folder "HockeyApp"
```

#### Use the HockeySDK.swift helper struct

If all former steps are completed you can call the `HockeySDK.setup()` method during the `application:didFinishLaunchingWithOptions` in the app delegate:

```
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		HockeySDK.setup()
		return true
	}
```


### Buglife-SDK

This repo contains the `BuglifeSDK` helper struct which takes care of the default Buglife SDK setup with `Shake` as default invocation option to trigger the Buglife view controller.

#### Integrate the Buglife SDK
To use the BuglifeSDK.swift helper struct you have to manually add the Buglife SDK to your project first. Use the preferred way to do this - at this time it's [CocoaPods](https://cocoapods.org).

#### Add the Buglife ID to the info plists
The helper struct will automatically read the IDs from the info plists. It's mandatory to add these with the key `BuglifeId` to all info plists in the project:

```
<key>BuglifeId</key>
<string>ABCDE...</string>
```

#### Add the BuglifeSDK.swift file to the project

Once the SDK is properly integrated and the Buglife ID set you have to add the `BuglifeSDK .swift` file to the Xcode project:

```
Project navigator > Submodules > Add files to "SMF-iOS-CommonProjectSetupFiles" > Choose the folder "Buglife"
```

#### Use the BuglifeSDK.swift helper struct

If all former steps are completed you can call the `BuglifeSDK.setup()` method during the `application:didFinishLaunchingWithOptions` in the app delegate:

```
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		BuglifeSDK.setup()
		return true
	}
```

## Scripts to be called during Build phase

###SwiftLint

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

**Make sure that `/.swiftlint.yml` is added to the gitignore file as the this default SwiftLint configuration file be automatically copied from the repo into the projects base folder.**

The Swiftlint configuration and lint call is integrated in the setup script. If it shouldn't be used you can pass the flag `--no-swiftlint`.

#### Optional: Call the SwiftLint script without using the setup script
If you want to copy the SwiftLint configuration and lint the code without integrating the setup script you can call `Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/copy-and-run-swiftlint-config.sh` directly.

#### Optional: Use an additional project specific SwiftLint config
If you have to modify the SwiftLint configuration for a specific project only you can create a new `.yml` file. By declaring this file during the SwiftLint call it will be processed with a higher priority before the default ".swiftlint.yml" configuration is processed. 

The adjusted script should look like this then:

```
cp Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/.swiftlint.yml ./

if which swiftlint >/dev/null; then
swiftlint lint --config .custom_swiftlint.yml
else
echo "SwiftLint does not exist, download from https://github.com/realm/SwiftLint"
fi
```

### Codebeat

[Codebeat](http://codebeat.co) is a service which provides static code analysis. The integration isn't done in the repo itself. But ignore and configuration files should be added to customize rules and ignore unwanted code (like generated source files).

The Codebeat configuration files copying is integrated in the setup script. If it shouldn't be used you can pass the flag `--no-codebeat`.

#### Optional: Call the Codebeat configuration script without using the setup script
If you want to copy the Codebeat configuration files without integrating the setup script you can call `Submodules/SMF-iOS-CommonProjectSetupFiles/Codebeat/copy-codebeat-config.sh` directly.

## Scripts to be called manually or by the CI

### MetaJSON

MetaJSON files are custom SMF JSON files which contains various information about the projects itself. These information is used to automatically update some generated confluence pages with eg. the app compatibility page and an overview over all used pods.

The scripts which create the MetaJSON files aren't called during the build phase locally but during fastlane builds of Alpha apps. The CI commits these JSON files to the projects repos.