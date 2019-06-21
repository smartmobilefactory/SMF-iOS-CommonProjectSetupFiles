//
//  SentrySDK+SMFLogger.swift
//
//  Copyright © 2019 Smart Mobile Factory. All rights reserved.
//

import Foundation
import Sentry
import SMFLogger

fileprivate struct SentryConstants {

	static let plistSentryDsn				= "SentryDsn"
	static let smfLogUploadMaxSizeDefault	= 5000
}

class SentrySDK: NSObject {

	// MARK: - Private static properties

	fileprivate static var shared			: SentrySDK?

	fileprivate static let isDebugBuild		: Bool = {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}()

	// MARK: - Private properties

	fileprivate var isInitialized			= false
	fileprivate var configuration			: Configuration?

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
	///   - configuration: Configuration object
	static func setup(configuration: SentrySDK.Configuration) {
		guard (self.isDebugBuild == false || configuration.enableDebug == true) else {
			return
		}

		let instance = (self.shared ?? SentrySDK())

		do {
			Client.shared = try Client(dsn: configuration.sentryDSN)
			Client.shared?.beforeSerializeEvent = { (event: Event) in
				event.environment = SentrySDK.Configuration.environment

				if
					(event.level != .debug),
					(configuration.enableSMFLogUpload == true),
					let loggerContents = Logger.logFilesContent(maxSize: configuration.smfLogUploadMaxSize) {
					event.message = loggerContents
				}
			}

			if (configuration.enableBreadcrumbs == true) {
				Client.shared?.enableAutomaticBreadcrumbTracking()
			}

			try Client.shared?.startCrashHandler()

			instance.configuration = configuration

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

	/// Send a custom event to Sentry for debugging.
	///
	///	- Parameters:
	///		- title					: title of the event
	///		- message				: description of what happened
	///		- additionalData		: dictionary of key/value pairs that will apear under Additional Data in Sentry
	///		- includeLoggerData		: if the event should also include the last part of SMFLogger
	///		- smfLogUploadMaxSize	: The max count of characters which should be uploaded
	static func sendEvent(title: String, message: String, additionalData: [String: Any]? = nil, includeLoggerData: Bool = true, smfLogUploadMaxSize: Int = (SentrySDK.shared?.configuration?.smfLogUploadMaxSize ?? SentryConstants.smfLogUploadMaxSizeDefault)) {
		let event = Event(level: .debug)

		if (additionalData != nil) {
			event.extra = additionalData
		}

		var fullMessage = "\(title) \n\n\(message)\n\n"

		if
			(includeLoggerData == true),
			let loggerContents = Logger.logFilesContent(maxSize: smfLogUploadMaxSize) {
			fullMessage.append("--------- DEBUG LOG ---------\n\n")
			fullMessage.append(loggerContents)
		}

		event.message = fullMessage

		Client.shared?.send(event: event, completion: nil)
	}
}

extension SentrySDK {

	struct Configuration {

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

		fileprivate var enableDebug			: Bool		= false
		fileprivate var sentryDSN			: String	= ""
		fileprivate var enableSMFLogUpload	: Bool		= true
		fileprivate var enableBreadcrumbs	: Bool		= true
		fileprivate var smfLogUploadMaxSize	: Int		= SentryConstants.smfLogUploadMaxSizeDefault

		/// Initializes a SentrySDK Configuration
		///
		///	- Parameters:
		///		- sentryDSN: supply this manually if you dont want it in the info.plist
		///		- enableSMFLogUpload: true if you want the SMFLogger logs to be submitted with a crash
		///		- enableBreadcrumbs: true if you want Sentry to attach the last user interaction before a crash
		///		- smfLogUploadMaxSize: The max count of characters which should be uploaded
		init(sentryDSN: String? = nil, enableSMFLogUpload: Bool = true, smfLogUploadMaxSize: Int = SentryConstants.smfLogUploadMaxSizeDefault, smfEnableBreadcrumbs: Bool = true, enableDebug: Bool = false) {

			// Get the Sentry DSN
			let dsnFromPlist = Bundle.main.object(forInfoDictionaryKey: SentryConstants.plistSentryDsn) as? String

			guard let _sentryDsn = (sentryDSN ?? dsnFromPlist) else {
				assertionFailure("Error: You have to set the `\(SentryConstants.plistSentryDsn)` key in the info plist or specify your own when initializing teh SDK.")
				return
			}

			self.enableDebug			= enableDebug
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
