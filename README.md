# SMF-iOS-CommonProjectSetupFiles

[![Language: Swift 5.3](https://img.shields.io/badge/Swift-5.2-orange.svg)](https://swift.org)
[![Xcode: Xcode 11.7](https://img.shields.io/badge/Xcode-11.7-orange.svg)](https://developer.apple.com/xcode)

This Repo contains our common project setup files.

Helpers which can be added manually to the Xcode project which should be used:

- [HockeySDK.swift](#hockeyapp-sdk)
- [SentrySDK.swift](#sentry-sdk)
- [BuglifeSDK.swift](#buglife-sdk)
- [LifetimeTrackerSDK](#lifetimetracker-sdk)

Scripts which should be called during the build phase:

- [SwiftLint](#swiftlint)
- [DrSwift](#drswift)
- [Xcode version check](#xcode-version-check)

### Setup

Go to the the projects `Build Phases` configuration, add a `New Run Script Phase` called "SMF-iOS-CommonProjectSetupFiles" and place it below `Compile Sources`.

The script for an app should look like:

```
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "${PRODUCT_TYPE}"
```

If the App uses SwiftUI, this call should be used:

```
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "${PRODUCT_TYPE}" --SwiftUI
```

If you're developing on a framework use this line on the all of your Unit Test targets:

```
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "com.apple.product-type.framework"
```

This will copy the Codebeat configuration files, copy the SwiftLint configuration and for DEBUG configuration run SwiftLint. In case either of them shouldn't be used in the project a flag can be used to opt out (see the readme below).

If you want to add more parameters, eg. to disable SwiftLint, you have to add them with separate `"`s. Otherwise the parameters will be interpreted as one string. Example with disabled SwiftLint:

```
"${SRCROOT}/Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh" --targettype "${PRODUCT_TYPE}" "--no-swiftlint"
```

# Documentation

## Helper classes

### HockeyApp-SDK

This repo contains the `HockeySDK` helper struct which takes care of the default HockeyApp SDK setup. The SDK will be initialized with the App ID and the Crash Manager started.

### Sentry-SDK

This repo contains the `SentrySKD` (plus the SMFLogger variant) helper struct which takes care of the default Sentry SDK setup. The SDK will be initialized with the Sentry DSN (in the info.plist).

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

If all former steps are completed you can call the `HockeySDK.setup()` method during the `applicationDidFinishLaunching(_:)` in the app delegate:

```
func applicationDidFinishLaunching(_ application: UIApplication) {
	HockeySDK.setup()
}
```

#### Customiztion

If you want to use a diferent `BITCrashManagerStatus` (the default is `.autoSend`) or want to enable crash reports also for debug builds you can send these as optional parameters:

```
HockeySDK.setup(withStatus: .alwaysAsk, configureHockeyAppAlsoForDebugBuildTypes: true)
```

#### Perform a test crash

If you want to test if crash reports are working you can perform a test crash. This will trigger a `fatalError()`. Note: If you didn't set `configureHockeyAppAlsoForDebugBuildTypes` to `true` you have to build the app as release app in order to capture crashes!

```
HockeySDK.performTestCrash()
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

If all former steps are completed you can call the `BuglifeSDK.setup()` method during the `applicationDidFinishLaunching (_:)` in the app delegate:

```
func applicationDidFinishLaunching(_ application: UIApplication) {
	BuglifeSDK.setup()
}
```

#### Customiztion

If you want to use a diferent `LIFEInvocationOptions` (the default is `.shake`) you can send it as optional parameter:

```
BuglifeSDK.setup(withOption: .screenshot)
```

### LifetimeTracker-SDK

This repo contains the `LifetimeTracker-SDK` helper struct and SMF base view controllers. Together with a custom protocol - which duplicates the LifetimeTracker configuration without exposing any LifetimeTracker type - the base view controller and setup can be added to a project even if LifetimeTracker is not part of the project.

Multiple `#if canImport(LifetimeTracker)` checks make sure that targets with LifetimeTracker are using it and that other targets work as well without any code changes.

### Integrate it into the project

- Add the folder `LifetimeTracker` to all targets
- Call `LifetimeTrackerSDK.setup()` in the app delegate
- Use the base view controllers as parent for all of your view controllers
- Use the LifetimeTracker Pod in the targets you want to


## Scripts to be called during Build phase

### SwiftLint

Swiftlint is integrated in SMF-iOS-CommonProjectSetupFiles itself. The current version is 0.28.1.

#### Integrate it into the project

**Make sure that `/.swiftlint.yml` is added to the gitignore file as the default SwiftLint configuration file be automatically copied from the repo into the projects base folder.**

The Swiftlint configuration and lint call is integrated in the [setup script](#setup). If it shouldn't be used you can pass the flag `--no-swiftlint`.

##### Excluded files from litting

You can declare excluded paths in the project specific swiftlint configuration file `.project-swiftlint.yml`. The file has to be placed in the same directoy as the copied `.swiftlint.yml` (usually the project root directory). The scripts *setup-common-project-files.sh* and *copy-and-run-swiftlint-config.sh* are automatically using the `.project-swiftlint.yml` file if it exists.

The syntax of the project specific configuration file has to match the one from the official swiftlint configuration:

```
excluded:
- App/HiDrive/Generated
```

##### Optional: Call the SwiftLint script without using the setup script
If you want to copy the SwiftLint configuration and lint the code without integrating the setup script you can call `Submodules/SMF-iOS-CommonProjectSetupFiles/SwiftLint/copy-and-run-swiftlint-config.sh` directly.

### DrSwift

[DrSwift](https://github.com/dduan/DrString) is integrated in SMF-iOS-CommonProjectSetupFiles itself. The current version is 0.4.2.

#### Integrate it into the project

DrString is configured to run when you execute `Submodules/SMF-iOS-CommonProjectSetupFiles/setup-common-project-files.sh` with [framework target configuration](#setup) parameters.

**Make sure that `/.drstring.toml` is added to the gitignore file as the DrSwift configuration file be automatically copied from the repo into the projects base folder.**

### Xcode version check

Building a project will trigger a Xcode version check to ensure you are working with the right Xcode version and an updated `smf.properties`. This script will look for the Xcode version specified in `smf.properties`. It will compare it to the Xcode version you are currently building the project and throw an error if it does not match.

The Xcode version check is integrated in the [setup script](#setup). If it shouldn't be used you can pass the flag `--no-xcodecheck`.

#### Optional: Call the Xcode version script without using the setup script
If you want to copy the Codebeat configuration files without integrating the setup script you can call `Submodules/SMF-iOS-CommonProjectSetupFiles/Xcode/check-xcode-version.sh` directly.
