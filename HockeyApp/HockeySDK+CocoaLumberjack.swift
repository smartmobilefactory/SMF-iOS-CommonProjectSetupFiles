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
		fileprivate var crashManagerStatus	: BITCrashManagerStatus

		init(hockeyAppID: String? = nil, crashManagerStatus: BITCrashManagerStatus = .autoSend, enableSMFLogUpload: Bool = false, enableOnDebug: Bool = true) {
			self.hockeyAppID			= hockeyAppID
			self.enableOnDebug			= enableOnDebug
			self.enableSMFLogUpload		= enableSMFLogUpload
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

	/**
	This will setup the HockeySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the `HockeyAppId` token taken from the info plists.

	- parameter crashManagerStatus: The `BITCrashManagerStatus` which determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user. The default value is `AutoSend`.
	- parameter configureHockeyAppAlsoForDebugBuildTypes: `Bool` which determines whether the HockeySDK should also be setup if the app is build with the `DEBUG` type. The Default value is `false`.
	*/
	static func setup(_ configuration: HockeySDK.Configuration) {

		let hockeySDK = self.shared ?? HockeySDK(configuration: configuration)

		let appIdKeyPassed = configuration.hockeyAppID
		let plistAppId = Bundle.main.object(forInfoDictionaryKey: HockeySDK.plistHockeyIDKey) as? String

		guard let _identifierKey = (appIdKeyPassed ?? plistAppId) else {
			assertionFailure("Warning: You have to set the `\(String(describing: configuration.hockeyAppID))` key in the info plist.")
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

	func logFilesContent(maxSize: Int) -> String {

		guard let sortedLogFileInfos = SMFLogger.latestFileLogger?.logFileManager.sortedLogFileInfos else {
			return ""
		}

		var description = ""
		for logFile in sortedLogFileInfos {
			if
				let logData = FileManager.default.contents(atPath: logFile.filePath),
				(logData.count > 0),
				let logMessage = String(data: logData, encoding: String.Encoding.utf8) {
					description.append(logMessage)
			}
		}

		if (description.characters.count > maxSize) {
			description = description.substring(from: description.index(description.startIndex, offsetBy: description.characters.count - maxSize - 1))
		}

		return description;
	}

	func applicationLog(for crashManager: BITCrashManager!) -> String! {
		guard (self.configuration?.enableSMFLogUpload == true) else {
			return nil
		}

		let description = self.logFilesContent(maxSize: 5000) // 5000 bytes should be enough!
		guard (description.isEmpty == false) else {
			return nil
		}

		return description
	}
}
