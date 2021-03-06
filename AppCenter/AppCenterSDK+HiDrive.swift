//
//  AppCenterSDK+SMFLogger.swift
//  SmartMobileFactory
//
//  Created by Konstantin Deichmann on 11.09.19.
//  Copyright © 2019 SmartMobileFactory. All rights reserved.
//

import Foundation
import AppCenter
import AppCenterCrashes
#if !os(macOS)
import AppCenterDistribute
#endif
import SMFLogger


fileprivate enum AppCenterConstants {

	static let appSecretKey					= "AppCenterAppSecret"
	static let smfLogUploadMaxCharCount		= 1_500_000 // With 1_500_000 chars we'll be at 1.5MB~
	static let crashLogFileName				= "SMFLogger.log"
}

class AppCenterSDK: NSObject {

	// MARK: - Private static properties

	fileprivate static let isDebugBuild		: Bool = {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}()

	// MARK: - Private properties

	fileprivate static var delegate			: AppCenterSDKDelegate?

	// MARK: - Public properties

	static var wasInitialized				: Bool {
		return AppCenter.isConfigured
	}

	// MARK: - Methods

	/// This will setup the AppCenterSDK with the common base configuration. Crashes will be detected if the app is build with the release build type.
	/// Distribution can be enabled using the configuration
	///
	/// - Parameters:
	///   - configuration: Configuration object
	static func setup(configuration: AppCenterSDK.Configuration = .default) {
		guard (self.isDebugBuild == false || configuration.enableDebug == true) else {
			return
		}

		self.delegate = AppCenterSDKDelegate(isLogUploadEnabled: configuration.isLogUploadEnabled)

		var services = [AnyClass]()

		#if !os(macOS)
		if (configuration.isDistributionEnabled == true) {
			services.append(Distribute.self)
		}
		#endif

		if (configuration.isCrashReportEnabled == true) {
			services.append(Crashes.self)
		}

		guard (services.isEmpty == false) else {
			return
		}

		AppCenter.start(withAppSecret: configuration.appSecret, services: services)
		Crashes.enabled = configuration.isCrashReportEnabled
		Crashes.delegate = self.delegate
	}

	#if !os(macOS)
	/// Returns True, if and only if the Service got started and is enabled.
	static var isDistributionEnabled: Bool {
		return Distribute.enabled
	}

	/// Will enable or disable the Distribution Feature of AppCenter
	/// While disabling works always.
	/// For enabling the Setup (aka. start) - Method should be called before.
	///
	/// Flow in the App, for Apps that want to dynamically change that State:
	/// - Call the Setup Method for with `isDistributionEnabled` set to true.
	/// - Disable Distribution using `enableDistribution(enabled: false)`
	/// - Enable Distribution at a later time using the same method
	///
	/// - Parameter enabled: Enable or Disable Distribtion
	static func enableDistribution(enabled: Bool = true) {
		Distribute.enabled = enabled
	}
	#endif

	/// Returns True, if and only if Crash Reporting is enabled.
	static var isCrashReportingEnabled: Bool {
		return Crashes.enabled
	}

	/// Will enable or disable the sending od crash reports to AppCenter
	/// While disabling works always.
	/// For enabling the Setup (aka. start) - Method should be called before.
	///
	/// Flow in the App, for Apps that want to dynamically change that State:
	/// - Call the Setup Method for with `isDistributionEnabled` set to true.
	/// - Disable Distribution using `enableDistribution(enabled: false)`
	/// - Enable Distribution at a later time using the same method
	///
	/// - Parameter enabled: Enable or Disable Distribtion
	static func enableCrashReporting(enabled: Bool = true) {
		Crashes.enabled = enabled
	}

	/// This will create a `fatalError` to crash the app.
	static func performTestCrash() {

		Crashes.generateTestCrash()
	}
}

extension AppCenterSDK {

	struct Configuration {

		fileprivate var enableDebug				: Bool
		fileprivate var appSecret				: String
		fileprivate var isDistributionEnabled	: Bool
		fileprivate var isCrashReportEnabled	: Bool
		fileprivate var isLogUploadEnabled		: Bool

		/// Initializes a AppCenterSDK Configuration
		///
		///	- Parameters:
		///		- appSecret: supply this manually if you dont want it in the info.plist
		///		- enableDebug: Should start the Services even for Debug, Default is false
		///		- isDistributionEnabled: Should start the Distribution Service, Default is false for Debug and Live apps, else true
		///		- isCrashReportEnabled: enables sending of crash reports, Default is true
		///		- isLogUploadEnabled: enables attachment of logs to crash reports, Default is true
		init(appSecret: String? = nil, enableDebug: Bool = false, isDistributionEnabled: Bool? = nil, isCrashReportEnabled: Bool = true, isLogUploadEnabled: Bool = true) {

			let appSecretFromBundle = Bundle.main.object(forInfoDictionaryKey: AppCenterConstants.appSecretKey) as? String

			guard let _appSecret = (appSecret ?? appSecretFromBundle) else {
				fatalError("You have to set the `\(AppCenterConstants.appSecretKey)` key in the info plist or specify your own when initializing the SDK.")
			}

			self.enableDebug			= enableDebug
			self.appSecret				= _appSecret
			self.isCrashReportEnabled	= isCrashReportEnabled
			self.isLogUploadEnabled		= isLogUploadEnabled

			#if DEBUG
			self.isDistributionEnabled	= isDistributionEnabled ?? false
			#elseif LIVE
			self.isDistributionEnabled	= isDistributionEnabled ?? false
			#else
			self.isDistributionEnabled	= isDistributionEnabled ?? true
			#endif
		}

		static var `default`: AppCenterSDK.Configuration {
			return Configuration()
		}
	}
}

private class AppCenterSDKDelegate	: NSObject, CrashesDelegate {

	private var isLogUploadEnabled	: Bool

	init(isLogUploadEnabled	: Bool) {
		self.isLogUploadEnabled = isLogUploadEnabled
	}

	func attachments(with crashes: Crashes, for errorReport: ErrorReport) -> [ErrorAttachmentLog]? {
		guard (self.isLogUploadEnabled == true) else {
			return []
		}

		return [ErrorAttachmentLog.attachment(withText: self.applicationLog, filename: AppCenterConstants.crashLogFileName)]
	}

	private var applicationLog: String {
		guard
			(self.isLogUploadEnabled == true),
			let description = Logger.logFilesContent(maxSize: AppCenterConstants.smfLogUploadMaxCharCount),
			(description.isEmpty == false) else {
				return "No Log found"
		}

		return description
	}
}

