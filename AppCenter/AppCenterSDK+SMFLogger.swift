//
//  AppCenterSDK+SMFLogger.swift
//  SmartMobileFactory
//
//  Created by Konstantin Deichmann on 11.09.19.
//  Copyright © 2019 SmartMobileFactory. All rights reserved.
//

import Foundation
import AppCenter
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

	// MARK: - Public properties

	static var wasInitialized				: Bool {
		return AppCenter.isConfigured
	}

	// MARK: - Methods

	/// This will setup the AppCenterSDK with the common base configuration.
	/// Distribution can be enabled using the configuration
	///
	/// - Parameters:
	///   - configuration: Configuration object
	static func setup(configuration: AppCenterSDK.Configuration = .default) {
		guard (self.isDebugBuild == false || configuration.enableDebug == true) else {
			return
		}

		let services = (configuration.isDistributionEnabled == true) ? [Distribute.self] : []

		AppCenter.start(withAppSecret: configuration.appSecret, services: services)
	}

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
}

extension AppCenterSDK {

	struct Configuration {

		fileprivate var enableDebug				: Bool
		fileprivate var appSecret				: String
		fileprivate var isDistributionEnabled	: Bool

		/// Initializes a AppCenterSDK Configuration
		///
		///	- Parameters:
		///		- appSecret: supply this manually if you dont want it in the info.plist
		///		- enableDebug: Should start the Services even for Debug, Default is false
		///		- isDistributionEnabled: Should start the Distribution Service, Default is false for Debug and Live apps, else true,
		init(appSecret: String? = nil, enableDebug: Bool = false, isDistributionEnabled: Bool? = nil) {

			let appSecretFromBundle = Bundle.main.object(forInfoDictionaryKey: AppCenterConstants.appSecretKey) as? String

			guard let _appSecret = (appSecret ?? appSecretFromBundle) else {
				fatalError("You have to set the `\(AppCenterConstants.appSecretKey)` key in the info plist or specify your own when initializing the SDK.")
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
