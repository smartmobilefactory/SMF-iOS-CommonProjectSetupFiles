//
//  HockeySDK.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hanas Seiffert on 29/08/16.
//  Copyright (c) 2016 Smart Mobile Factory. All rights reserved.
//

import Foundation
import HockeySDK

struct HockeySDK {

	// MARK: - Public Properties

	static let identifierKey	= "HockeyAppId"

	// MARK: - Private Properties

	fileprivate static var isDebugBuild: Bool {
		#if DEBUG
			return true
		#else
			return false
		#endif
	}

	// MARK: - Methods

	/**
	This will setup the HockeySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the `HockeyAppId` token taken from the info plists.

	- parameter crashManagerStatus: The `BITCrashManagerStatus` which determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user. The default value is `AutoSend`.
	- parameter configureHockeyAppAlsoForDebugBuildTypes: `Bool` which determines whether the HockeySDK should also be setup if the app is build with the `DEBUG` type. The Default value is `false`.
	*/
	static func setup(withStatus crashManagerStatus: BITCrashManagerStatus = .autoSend, configureHockeyAppAlsoForDebugBuildTypes: Bool = false) {
		if let
			_identifier = Bundle.main.object(forInfoDictionaryKey: identifierKey) as? String,
			(configureHockeyAppAlsoForDebugBuildTypes == true || self.isDebugBuild == false) {
				BITHockeyManager.shared().configure(withIdentifier: _identifier)
				BITHockeyManager.shared().authenticator.authenticateInstallation()
				BITHockeyManager.shared().isCrashManagerDisabled = (crashManagerStatus == .disabled)
				BITHockeyManager.shared().crashManager.crashManagerStatus = crashManagerStatus
				BITHockeyManager.shared().start()
		} else {
			print("Warning: You have to set the `\(identifierKey)` key in the info plist.")
		}
	}

	/**
	Modifies the crash mananger status. This method should be used to enable or disable crash reports during the app usage.

	- parameter crashManagerStatus: The `BITCrashManagerStatus` which determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user. The default value is `AutoSend`.
	*/
	static func updateCrashManagerStatus(to status: BITCrashManagerStatus) {
		self.setup(withStatus: status)
	}

	/**
	This will create a `fatalError` to crash the app.

	- Warning: The app has to be build with the RELEASE build type or `configureHockeyAppAlsoForNonReleaseBuildTypes` set to `true` and no debugger can be attached in order the receive crash reports on HockeyApp.
	*/
	static func performTestCrash() {
		fatalError("This is a test crash to trigger a crash report in the HockeyApp")
	}
}
