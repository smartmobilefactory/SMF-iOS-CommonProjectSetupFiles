//
//  Buglife.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hanas Seiffert on 29/08/16.
//  Copyright © 2016 Smart Mobile Factory. All rights reserved.
//

import Foundation
import Buglife

struct BuglifeSDKHelper {

	static let IdentifierKey	= "BuglifeId"

	/**
	This will setup the Buglife sdk with the common base configuration.

	- parameter invocationOptions: The `LIFEInvocationOptions` to determine which invocation option should be used to trigger Buglife. The default is `.Shake`.
	*/
	static func setup(invocationOptions: LIFEInvocationOptions = .Shake) {
		let identifier = NSBundle.mainBundle().entryInPListForKey(IdentifierKey)
		Buglife.sharedBuglife().startWithAPIKey(identifier)
		Buglife.sharedBuglife().invocationOptions = invocationOptions
	}
}
