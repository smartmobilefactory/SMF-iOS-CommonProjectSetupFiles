//
//  SMFBaseTableViewController.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hans Seiffert on 04.12.18.
//  Copyright © 2018 Smart Mobile Factory GmbH. All rights reserved.
//

import UIKit

#if canImport(LifetimeTracker)

import LifetimeTracker

#endif

class SMFBaseTableViewController: UITableViewController, SMFLifetimeTrackable {

	// MARK: - LifetimeTracker Configuration (without import)

	class var lt_maxCount: Int {
		return 1
	}

	class var lt_groupName: String? {
		return String(describing: self)
	}

	class var lt_groupMaxCount: Int? {
		return nil
	}

	// MARK: - LifetimeTracker Configuration (with import)

#if canImport(LifetimeTracker)

	class var lifetimeConfiguration: LifetimeConfiguration {
		let lifetimeConfiguration = LifetimeConfiguration(maxCount: self.lt_maxCount)
		lifetimeConfiguration.groupName = self.lt_groupName
		lifetimeConfiguration.groupMaxCount = self.lt_groupMaxCount
		return lifetimeConfiguration
	}

	// MARK: - Initialization

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		self.trackLifetime()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.trackLifetime()
	}

#endif
}

#if canImport(LifetimeTracker)

extension SMFBaseTableViewController: LifetimeTrackable {}

#endif
