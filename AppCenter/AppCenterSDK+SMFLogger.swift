//
//  AppCenterSDK+SMFLogger.swift
//  Newsletter2Go
//
//  Created by Konstantin Deichmann on 11.09.19.
//  Copyright © 2019 Newsletter2Go GmbH. All rights reserved.
//

import Foundation
import AppCenter
import AppCenterCrashes
import AppCenterDistribute

fileprivate enum AppCenterConstants {

	static let appSecretKey					= "AppCenterAppSecret"
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

	fileprivate var isInitialized			= false
	fileprivate var configuration			: Configuration?

	// MARK: - Public properties

	static var wasInitialized				: Bool {
		return MSAppCenter.isConfigured()
	}

	// MARK: - Methods

	/// This will setup the SentrySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the sentry dsn taken from the info plists.
	///
	/// - Parameters:
	///   - configuration: Configuration object
	static func setup(configuration: AppCenterSDK.Configuration = .default) {
		guard (self.isDebugBuild == false || configuration.enableDebug == true) else {
			return
		}

		let services = (configuration.isDistributionEnabled == true) ? [MSCrashes.self, MSDistribute.self] : [MSCrashes.self]

		MSAppCenter.start(configuration.appSecret, withServices: services)
	}

	/// This will create a `fatalError` to crash the app.
	static func performTestCrash() {

		MSCrashes.generateTestCrash()
	}
}

extension AppCenterSDK {

	struct Configuration {

		fileprivate var enableDebug				: Bool		= false
		fileprivate var appSecret				: String	= ""
		fileprivate var isDistributionEnabled	: Bool

		/// Initializes a AppCenterSDK Configuration
		///
		///	- Parameters:
		///		- appSecret: supply this manually if you dont want it in the info.plist
		init(appSecret: String? = nil, enableDebug: Bool = false, isDistributionEnabled: Bool? = nil) {

			let appSecretFromBundle = Bundle.main.object(forInfoDictionaryKey: AppCenterConstants.appSecretKey) as? String

			guard let _appSecret = (appSecret ?? appSecretFromBundle) else {
				assertionFailure("Error: You have to set the `\(AppCenterConstants.appSecretKey)` key in the info plist or specify your own when initializing teh SDK.")
				return
			}

			self.enableDebug			= enableDebug
			self.appSecret				= _appSecret

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
