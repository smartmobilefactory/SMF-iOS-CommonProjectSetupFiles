//
//  SentrySDK.swift
//
//  Copyright © 2019 Smart Mobile Factory. All rights reserved.
//

import Foundation
import Sentry

class SentrySDK: NSObject {

	// MARK: - Private static properties

	fileprivate static var shared			: SentrySDK?

	fileprivate static let plistSentryDsn	= "SentryDsn"

	fileprivate static let isDebugBuild		: Bool = {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}()

	fileprivate static let environment		: String = {
		#if ALPHA
		return "alpha"
		#endif

		#if BETA
		return "beta"
		#endif

		#if LIVE
		return "live"
		#endif
	}()

	// MARK: - Private properties

	fileprivate var isInitialized			= false

	// MARK: - Public properties

	static var wasInitialized				: Bool {
		return (SentrySDK.shared?.isInitialized ?? false)
	}

	// MARK: - Initialization

	override init() {
		super.init()

		SentrySDK.shared = self
	}

	// MARK: - Methods

	/// This will setup the SentrySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the sentry dsn taken from the info plists.
	///
	/// - Parameters:
	///   - configuration: sentry dsn string
	static func setup(sentryDsn: String? = nil) {

		// Get the Sentry dsn
		let idFromPlist = Bundle.main.object(forInfoDictionaryKey: SentrySDK.plistSentryDsn) as? String

		guard let _sentryDsn = (sentryDsn ?? idFromPlist) else {
			assertionFailure("Error: You have to set the `\(SentrySDK.plistSentryDsn)` key in the info plist.")
			return
		}

		// Make sure SentrySDK is not setup in a debug build
		guard (self.isDebugBuild == false) else {
			// Configure SentrySDK only for non debug builds or if the exception flag is set to true
			return
		}

		let instance = (self.shared ?? SentrySDK())

		Client.shared = try? Client(dsn: _sentryDsn)
		Client.shared?.beforeSerializeEvent = { (event: Event) in
				event.environment = self.environment
			}

		try? Client.shared?.startCrashHandler()
		instance.isInitialized = true
	}

	/// This will create a `fatalError` to crash the app.
	static func performTestCrash() {

		guard (self.shared?.isInitialized == true) else {
			assertionFailure("Error: You have to setup `SentrySDK` before performing a test crash. The test crash won't be performed otherwise.")
			return
		}

		Client.shared?.reportUserException("TestCrash", reason: "Only testing crashes", language: "swift", lineOfCode: "23", stackTrace: [], logAllThreads: false, terminateProgram: true)
		fatalError("This is a test crash to trigger a crash report in Sentry Dashboard")
	}
}
