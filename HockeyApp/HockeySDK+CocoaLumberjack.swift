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

	struct Configuration {
		fileprivate var hockeyAppID			: String?
		fileprivate var enableSMFLogUpload	: Bool
		fileprivate var enableOnDebug		: Bool
		fileprivate let smfLogUploadMaxSize	: Int
		fileprivate var crashManagerStatus	: BITCrashManagerStatus

		/// Initialized a HockeySDK Configuration
		///
		/// - Parameters:
		///   - hockeyAppID: app's hockeyAppID
		///   - crashManagerStatus: initial crash manager status
		///   - enableSMFLogUpload: true if you want the SMFLogger logs to be submitted with a crash
		///   - enableOnDebug: true if you want crash reporting to be enabled during development (Debug builds)
		init(hockeyAppID: String? = nil, crashManagerStatus: BITCrashManagerStatus = .autoSend, enableSMFLogUpload: Bool = true, smfLogUploadMaxSize: Int = 5000, enableOnDebug: Bool = false) {
			self.hockeyAppID			= hockeyAppID
			self.enableOnDebug			= enableOnDebug
			self.enableSMFLogUpload		= enableSMFLogUpload
			self.smfLogUploadMaxSize	= smfLogUploadMaxSize
			self.crashManagerStatus		= crashManagerStatus
		}

		static var `default`: HockeySDK.Configuration {
			return Configuration()
		}
	}

	// MARK: - Internal Properties

	internal static var shared			: HockeySDK?

	// MARK: - Private Properties

	private static let plistHockeyIDKey	= "HockeyAppId"
	fileprivate var configuration		: HockeySDK.Configuration?

	fileprivate static let isDebugBuild: Bool = {
		#if DEBUG
			return true
		#else
			return false
		#endif
	}()

	init(configuration: HockeySDK.Configuration) {
		self.configuration = configuration

		super.init()

		HockeySDK.shared = self
	}

	// MARK: - Methods

	/// This will setup the HockeySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the `HockeyAppId` token taken from the info plists.
	///
	/// - Parameter configuration: HockeySDK Configuration
	static func setup(_ configuration: HockeySDK.Configuration) {

		let hockeySDK = (self.shared ?? HockeySDK(configuration: configuration))

		let appIdKeyPassed = configuration.hockeyAppID
		let plistAppId = Bundle.main.object(forInfoDictionaryKey: HockeySDK.plistHockeyIDKey) as? String

		guard let _identifierKey = (appIdKeyPassed ?? plistAppId) else {
			assertionFailure("You have to set the `\(HockeySDK.plistHockeyIDKey)` key in the info plist.")
			return
		}

		guard (configuration.enableOnDebug == true || self.isDebugBuild == false) else {
			// Configure HockeyApp only for non debug builds or if the exception flag is set to true
			return
		}

		BITHockeyManager.shared().configure(withIdentifier: _identifierKey, delegate: hockeySDK)
		BITHockeyManager.shared().start()
		BITHockeyManager.shared().authenticator.authenticateInstallation()
		BITHockeyManager.shared().crashManager.crashManagerStatus = configuration.crashManagerStatus
	}

	/**
	Modifies the crash mananger status. This method should be used to enable or disable crash reports during the app usage.

	- parameter crashManagerStatus: The `BITCrashManagerStatus` which determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user. The default value is `AutoSend`.
	*/
	func updateCrashManagerStatus(to status: BITCrashManagerStatus) {
		BITHockeyManager.shared().crashManager.crashManagerStatus = status
	}

	/**
	This will create a `fatalError` to crash the app.

	- Warning: The app has to be build with the RELEASE build type or `configureHockeyAppAlsoForNonReleaseBuildTypes` set to `true` and no debugger can be attached in order the receive crash reports on HockeyApp.
	*/
	func performTestCrash() {
		fatalError("This is a test crash to trigger a crash report in the HockeyApp")
	}
}

// MARK: - BITHockeyManagerDelegate

extension HockeySDK: BITHockeyManagerDelegate {

	func applicationLog(for crashManager: BITCrashManager!) -> String! {
		guard
			let configuration = self.configuration,
			(configuration.enableSMFLogUpload == true),
			let description = SMFLogger.logFilesContent(maxSize: configuration.smfLogUploadMaxSize),
			(description.isEmpty == false) else {
				return nil
		}

		return description
	}
}
