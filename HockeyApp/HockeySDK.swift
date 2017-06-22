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

	static let identifierKey			= "HockeyAppId"

	// MARK: - Private Properties

	private static var isInitialized	= false

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

		guard let _identifierKey = Bundle.main.object(forInfoDictionaryKey: identifierKey) as? String else {
			assertionFailure("Warning: You have to set the `\(identifierKey)` key in the info plist.")
			return
		}

		guard (configureHockeyAppAlsoForDebugBuildTypes == true || self.isDebugBuild == false) else {
			// Configure HockeyApp only for non debug builds or if the exception flag is set to true
			return
		}

		BITHockeyManager.shared().configure(withIdentifier: _identifierKey)
		BITHockeyManager.shared().start()
		BITHockeyManager.shared().authenticator.authenticateInstallation()
		BITHockeyManager.shared().crashManager.crashManagerStatus = crashManagerStatus

		self.isInitialized = true
	}

	/**
	Modifies the crash mananger status. This method should be used to enable or disable crash reports during the app usage.

	- parameter crashManagerStatus: The `BITCrashManagerStatus` which determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user. The default value is `AutoSend`.
	*/
	static func updateCrashManagerStatus(to status: BITCrashManagerStatus) {
		guard (self.isInitialized == true) else {
			self.setup(status, configureHockeyAppAlsoForNonReleaseBuildTypes: false)
			return
		}

		BITHockeyManager.sharedHockeyManager().crashManager.crashManagerStatus = status
	}

	/**
	This will create a `fatalError` to crash the app.

	- Warning: The app has to be build with the RELEASE build type or `configureHockeyAppAlsoForNonReleaseBuildTypes` set to `true` and no debugger can be attached in order the receive crash reports on HockeyApp.
	*/
	static func performTestCrash() {
		fatalError("This is a test crash to trigger a crash report in the HockeyApp")
	}
}
