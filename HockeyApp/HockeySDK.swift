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

	static let IdentifierKey	= "HockeyAppId"

	/**
	This will setup the HockeySDK with the common base configuration. Crashes will be detected if the app is build with the release build type and the `HockeyAppId` token taken from the info plists.
	
	- parameter crashManagerStatus: The `BITCrashManagerStatus` which determines whether crashes should be send to HockeyApp and whether it should be done automatically or manually by the user. The default value is `AutoSend`.
	*/
	static func setup(crashManagerStatus: BITCrashManagerStatus = .AutoSend) {
		#if RELEASE
			let identifier = NSBundle.mainBundle().entryInPListForKey(IdentifierKey)
			BITHockeyManager.sharedHockeyManager().configureWithIdentifier(identifier)
			BITHockeyManager.sharedHockeyManager().startManager()
			BITHockeyManager.sharedHockeyManager().authenticator.authenticateInstallation()
			BITHockeyManager.sharedHockeyManager().crashManager.crashManagerStatus = .AutoSend
		#endif
	}
}
