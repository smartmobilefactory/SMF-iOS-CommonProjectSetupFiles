//
//  LifetimeTrackerSDK.swift
//  SMF-iOS-CommonProjectSetupFiles
//
//  Created by Hans Seiffert on 04.12.18.
//  Copyright © 2018 Smart Mobile Factory GmbH. All rights reserved.
//

import Foundation

#if canImport(LifetimeTracker)
import LifetimeTracker
#endif

struct LifetimeTrackerSDK {

	public enum Visibility {
		case alwaysHidden
		case alwaysVisible
		case visibleWithIssuesDetected

#if canImport(LifetimeTracker)

		var libraryRepresentation: LifetimeTrackerDashboardIntegration.Visibility {
			switch self {
			case .alwaysHidden:					return LifetimeTrackerDashboardIntegration.Visibility.alwaysHidden
			case .alwaysVisible:				return LifetimeTrackerDashboardIntegration.Visibility.alwaysVisible
			case .visibleWithIssuesDetected:	return LifetimeTrackerDashboardIntegration.Visibility.visibleWithIssuesDetected
			}
		}

#endif
	}

	static func setup(with visibility: LifetimeTrackerSDK.Visibility = .visibleWithIssuesDetected) {
#if canImport(LifetimeTracker)
		LifetimeTracker.setup(onUpdate: LifetimeTrackerDashboardIntegration(visibility: visibility.libraryRepresentation, style: .circular).refreshUI)
#endif
	}
}
