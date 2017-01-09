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

	static let identifierKey	= "BuglifeId"

	/**
	This will setup the Buglife SDK with the common base configuration.

	- parameter invocationOptions: The `LIFEInvocationOptions` to determine which invocation option should be used to trigger Buglife. The default is `.Shake`.
	*/
	static func setup(withOption invocationOptions: LIFEInvocationOptions = .shake) {
		if let _identifier = Bundle.main.object(forInfoDictionaryKey: identifierKey) as? String {
			Buglife.shared().start(withAPIKey: _identifier)
			Buglife.shared().invocationOptions = invocationOptions
		} else {
			print("Warning: You have to the set the `\(identifierKey)` key in the info plist.")
		}
	}
}
