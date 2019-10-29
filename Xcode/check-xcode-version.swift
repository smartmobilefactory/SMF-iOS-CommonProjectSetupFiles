#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

let env = ProcessInfo.processInfo.environment

guard
	let path = env["PROJECT_DIR"],
	var url = URL(string: "file://" + path),
	let xcodeVersion = env["XCODE_VERSION_ACTUAL"] else {
		exit(0)
}

url.appendPathComponent("Config.json")

guard
	let data = try? Data(contentsOf: url),
	let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
	let project = json["project"] as? [String: Any],
	let projectXcodeVersion = project["xcode_version"] as? String else {
		fatalError("'xcode_version' not found, please check your Config.json")
}

let xcodeVersionCleaned = xcodeVersion.trimmingCharacters(in: .init(charactersIn: "0"))
let projectXcodeVersionCleaned = projectXcodeVersion.replacingOccurrences(of: ".", with: "")

if (xcodeVersionCleaned != projectXcodeVersionCleaned) {
	fatalError("Xcode Version mismatch: please open Project with Xcode \(projectXcodeVersion) or change Xcode Version in Config.json")
}

exit(0)
