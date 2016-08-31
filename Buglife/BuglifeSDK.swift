//
//  BuglifeSDK.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hanas Seiffert on 29/08/16.
//  Copyright © 2016 Smart Mobile Factory. All rights reserved.
//

import Foundation
import Buglife

struct BuglifeSDK {

	static let IdentifierKey	= "BuglifeId"

	/**
	This will setup the Buglife SDK with the common base configuration.

	- parameter invocationOptions: The `LIFEInvocationOptions` to determine which invocation option should be used to trigger Buglife. The default is `.Shake`.
	*/
	static func setup(invocationOptions: LIFEInvocationOptions = .Shake) {
		if let _identifier = NSBundle.mainBundle().objectForInfoDictionaryKey(IdentifierKey) as? String {
			Buglife.sharedBuglife().startWithAPIKey(_identifier)
			Buglife.sharedBuglife().invocationOptions = invocationOptions
		} else {
			print("Warning: You have to the set the `\(IdentifierKey)` key in the info plist.")
		}
	}
}
