//
//  HockeySDK.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hanas Seiffert on 29/08/16.
//  Copyright (c) 2016 Smart Mobile Factory. All rights reserved.
//

import Foundation
import HockeySDK
import SMFLogger

class HockeySDK: NSObject {

	// MARK: - Private static properties

	fileprivate static var shared			: HockeySDK?

	fileprivate static let plistHockeyIDKey	= "HockeyAppId"

	fileprivate static let isDebugBuild		: Bool = {
		#if DEBUG
			return true
		#else
			return false
		#endif
	}()

	// MARK: - Private properties

	fileprivate var isInitialized			= false

	fileprivate var configuration			: HockeySDK.Configuration?

	// MARK: - Public properties

	static var wasInitialized				: Bool {
		return (HockeySDK.shared?.isInitialized ?? false)
	}

	// MARK: - Initialization

	init(configuration: HockeySDK.Configuration) {
		self.configuration = configuration

		super.init()

		HockeySDK.shared = self
	}

	// MARK: - Methods

	/// This will setup the HockeySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the `HockeyAppId` token taken from the info plists.
	///
	/// - Parameters:
	///   - configuration: HockeySDK Configuration
	static func setup(_ configuration: HockeySDK.Configuration) {

		// Get the HockeyApp identifier
		let idFromConfiguration = configuration.hockeyAppID
		let idFromPlist = Bundle.main.object(forInfoDictionaryKey: HockeySDK.plistHockeyIDKey) as? String

		guard let _identifierKey = (idFromConfiguration ?? idFromPlist) else {
			assertionFailure("Error: You have to set the `\(HockeySDK.plistHockeyIDKey)` key in the info plist.")
			return
		}

		// Make sure HockeySDK is not setup in a debug build
		guard (self.isDebugBuild == false) else {
			// Configure HockeyApp only for non debug builds or if the exception flag is set to true
			return
		}

		let instance = (self.shared ?? HockeySDK(configuration: configuration))
		BITHockeyManager.shared().configure(withIdentifier: _identifierKey, delegate: instance)
		BITHockeyManager.shared().crashManager.isAutoSubmitCrashReport = configuration.autoSubmitCrashReport
		BITHockeyManager.shared().start()

		instance.isInitialized = true
	}

	/// Modifies the autoSubmitCrashReport value. This method should be used to enable or disable crash reports during the app usage.
	///
	/// - Parameters:
	///   - autoSubmitCrashReport: Determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user.
	static func updateAutoSubmitCrashReport(to autoSubmitCrashReport: Bool) {
		guard (self.shared?.isInitialized == true) else {
			assertionFailure("Error: You have to setup `HockeySDK` before updating the autoSubmitCrashReport. The update won't be performed.")
			return
		}

		BITHockeyManager.shared().crashManager.isAutoSubmitCrashReport = autoSubmitCrashReport
	}

	/// This will create a `fatalError` to crash the app.
	static func performTestCrash() {
		guard (self.shared?.isInitialized == true) else {
			assertionFailure("Error: You have to setup `HockeySDK` before performing a test crash. The test crash won't be performed otherwise.")
			return
		}

		fatalError("This is a test crash to trigger a crash report in the HockeyApp")
	}
}

// MARK: - HockeySDK.Configuration

extension HockeySDK {

	struct Configuration {
		fileprivate var hockeyAppID				: String?
		fileprivate var autoSubmitCrashReport	: Bool
		fileprivate var enableSMFLogUpload		: Bool
		fileprivate let smfLogUploadMaxSize		: Int

		/// Initialized a HockeySDK Configuration
		///
		/// - Parameters:
		///   - hockeyAppID: The app's hockeyAppID
		///   - autoSubmitCrashReport: true if the crash should be reported automatically. The default value is `true`.
		///   - enableSMFLogUpload: true if you want the SMFLogger logs to be submitted with a crash
		///   - smfLogUploadMaxSize: The max count of characters which should be uploaded
		init(hockeyAppID: String? = nil, autoSubmitCrashReport: Bool = true, enableSMFLogUpload: Bool = true, smfLogUploadMaxSize: Int = 5000) {
			self.hockeyAppID			= hockeyAppID
			self.enableSMFLogUpload		= enableSMFLogUpload
			self.smfLogUploadMaxSize	= smfLogUploadMaxSize
			self.autoSubmitCrashReport	= autoSubmitCrashReport
		}

		static var `default`: HockeySDK.Configuration {
			return Configuration()
		}
	}
}

// MARK: - BITHockeyManagerDelegate

extension HockeySDK: BITHockeyManagerDelegate {

	func applicationLog(for crashManager: BITCrashManager!) -> String! {
		guard
			let configuration = self.configuration,
			(configuration.enableSMFLogUpload == true),
			let description = Logger.logFilesContent(maxSize: configuration.smfLogUploadMaxSize),
			(description.isEmpty == false) else {
				return nil
		}

		return description
	}
}
