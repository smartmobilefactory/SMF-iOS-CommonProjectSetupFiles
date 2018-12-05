//
//  SMFLifetimeTrackable.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hans Seiffert on 04.12.18.
//  Copyright © 2018 Smart Mobile Factory GmbH. All rights reserved.
//

import UIKit

/// Protocol which duplicates the configuration from LifetimeTracker
/// It is used to enable projects to only add LifetimeTracker to some targets (e.g. not to the Live app) as this protocol defines everything which is needed without the need to import LifetimeTracker
protocol SMFLifetimeTrackable {

	static var lt_maxCount: Int { get }

	static var lt_groupName: String? { get }

	static var lt_groupMaxCount: Int? { get }
}
