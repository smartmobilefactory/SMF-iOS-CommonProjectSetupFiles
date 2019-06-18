//
//  SentrySDK+SMFLogger.swift
//
//  Copyright © 2019 Smart Mobile Factory. All rights reserved.
//

import Foundation
import Sentry
import SMFLogger

class SentrySDK: NSObject {

	// MARK: - Private static properties

	fileprivate static var shared			: SentrySDK?

	// MARK: - Private properties

	fileprivate var isInitialized					= false

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
	static func setup(configuration: SentrySDK.Configuration) {

		// Make sure SentrySDK is not setup in a debug build
//		guard (self.isDebugBuild == false) else {
//			// Configure SentrySDK only for non debug builds or if the exception flag is set to true
//			return
//		}

		let instance = (self.shared ?? SentrySDK())

		do {
			Client.shared = try Client(dsn: configuration.sentryDSN)
			Client.shared?.beforeSerializeEvent = { (event: Event) in
				event.environment = SentrySDK.Configuration.environment

				if	(configuration.enableSMFLogUpload == true),
					let loggerContents = Logger.logFilesContent(maxSize: configuration.smfLogUploadMaxSize) {
						event.message = loggerContents
				}
			}

			if (configuration.enableBreadcrumbs == true) {
				Client.shared?.enableAutomaticBreadcrumbTracking()
			}

			try Client.shared?.startCrashHandler()
			instance.isInitialized = true
		} catch let error {
			Log.Channel.Manager.sentry.error("Error initialising sentry: \(error.localizedDescription)")
		}
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

extension SentrySDK {

	struct Configuration {
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

		fileprivate var sentryDSN			: String	= ""
		fileprivate var enableSMFLogUpload	: Bool		= true
		fileprivate var enableBreadcrumbs	: Bool		= true
		fileprivate var smfLogUploadMaxSize	: Int		= 5000

		/// Initializes a SentrySDK Configuration
		///
		///	- Parameters:
		///		- sentryDSN: supply this manually if you dont want it in the info.plist
		///		- enableSMFLogUpload: true if you want the SMFLogger logs to be submitted with a crash
		///		- enableBreadcrumbs: true if you want Sentry to attach the last user interaction before a crash
		///		- smfLogUploadMaxSize: The max count of characters which should be uploaded
		init(sentryDSN: String? = nil, enableSMFLogUpload: Bool = true, smfLogUploadMaxSize: Int = 5000, smfEnableBreadcrumbs: Bool = true) {

			// Get the Sentry DSN
			let dsnFromPlist = Bundle.main.object(forInfoDictionaryKey: SentrySDK.Configuration.plistSentryDsn) as? String

			guard let _sentryDsn = (sentryDSN ?? dsnFromPlist) else {
				assertionFailure("Error: You have to set the `\(SentrySDK.Configuration.plistSentryDsn)` key in the info plist or specify your own when initializing teh SDK.")
				return
			}

			self.sentryDSN				= _sentryDsn
			self.enableBreadcrumbs		= smfEnableBreadcrumbs
			self.enableSMFLogUpload		= enableSMFLogUpload
			self.smfLogUploadMaxSize	= smfLogUploadMaxSize
		}

		static var `default`: SentrySDK.Configuration {
			return Configuration()
		}
	}
}
