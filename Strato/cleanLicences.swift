#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

do {
	guard (CommandLine.argc == 2) else {
		throw ScriptError.arguments
	}

	let path = CommandLine.arguments[1]

	try cleanupLicenses(atPath: path)
} catch {
	// The extra white lines in the string are there to make the description & usage more visible
	fatalError("""


	-----------------------------------
	CONTEXT: Script made for the HiDrive project in order to clean up the Pods-acknowledgements.plist. It should be run in the Podfile after the pod installation.
	See https://smartmobilefactory.atlassian.net/browse/STRFRAMEWORK-2640

	SCRIPT DESCRIPTION: Cleans up the Pod-acknowledgements.plist file from:
		- Pods without a licence
		- Pods with closed source
		- Internal SMF HiDrive-iOS framework
	Moreover, it also removes "SMF" or "SMF-" when set as a prefix on a Pod name
	At the end, it sorts the Pods by name alphabetically, and override the file at the path given as argument

	USAGE: `cleanLicences.swift *path*`
	- path: Absolute path to the Pod-acknowledgements.plist to clean up

	ERROR: \(error)
	-----------------------------------




	""")
}

// ----- Script ends here, below is the model and code used in the script

enum ScriptError: Error {
	case arguments
}

struct LicenseContainer: Codable {

	let licenses: [License]

	enum CodingKeys: String, CodingKey {
		case licenses = "PreferenceSpecifiers"
	}
}

struct License: Codable {

	let title: String
	let license: String?
	let footer: String?

	enum CodingKeys: String, CodingKey {
		case title = "Title"
		case license = "License"
		case footer = "FooterText"
	}
}

/// Cleans up the Pod-acknowledgements.plist file from:
/// - Pods without a licence
/// - Pods with closed source
/// - Internal SMF HiDrive-iOS framework
/// Moreover, it also removes "SMF" or "SMF-" when set as a prefix on a Pod name (see https://smartmobilefactory.atlassian.net/browse/STRFRAMEWORK-2640) 
/// At the end, it sorts the Pods by name alphabetically, and override the file at `path`
func cleanupLicenses(atPath path: String) throws {
	let url = URL(fileURLWithPath: path)
	let data = try Data(contentsOf: url)
	let decoder = PropertyListDecoder()
	let container = try decoder.decode(LicenseContainer.self, from: data)

	let licenses = container.licenses
		.filter { (license: License) -> Bool in
			guard let licenseString = license.license else {
				return false
			}

			guard (licenseString.isEmpty == false) else {
				return false
			}

			guard (licenseString.starts(with: "Closed Source") == false) else {
				return false
			}

			guard (license.title.starts(with: "HiDrive-iOS-") == false) else {
				return false
			}

			return true
		}
		.map { (license: License) -> License in
			if let range = license.title.range(of: "SMF-") {
				var title = license.title
				title.replaceSubrange(range, with: "")
				return License(title: title, license: license.license, footer: license.footer)
			} else if let range = license.title.range(of: "SMF") {
				var title = license.title
				title.replaceSubrange(range, with: "")
				return License(title: title, license: license.license, footer: license.footer)
			} else {
				return license
			}
		}

	let sortedLicences = licenses.sorted { $0.title < $1.title }
	let sortedContainer = LicenseContainer(licenses: sortedLicences)

	let encoder = PropertyListEncoder()
	encoder.outputFormat = .xml
	let sortedData = try encoder.encode(sortedContainer)
	try sortedData.write(to: url)
}
