# SMF-iOS-CommonProjectSetupFiles

This Repo contains our common project setup files:

- SwiftLint 
- HockeySDK.swift**\***
- BuglifeSDK.swift**\***

**\*** optional Files which doesn't have to be in each project and should only be added to Xcode if they should be used.

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

**Make sure that `.swiftlint.yml` is added to the gitignore file as the this default SwiftLint configuration file be automatically copied from the repo into the projects base folder.**

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

##HockeyApp SDK

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


##Buglife SDK

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

