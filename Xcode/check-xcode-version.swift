#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

let env = ProcessInfo.processInfo.environment

guard
	let path = env["PROJECT_DIR"],
	var url = URL(string: "file://" + path),
	let projectPath = env["PROJECT_FILE_PATH"],
	let xcodeVersionMajor = env["XCODE_VERSION_MAJOR"],
	let xcodeVersion = env["XCODE_VERSION_ACTUAL"] else {
		exit(0)
}

url.appendPathComponent("Config.json")

guard
	let data = try? Data(contentsOf: url),
	let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
	let project = json["project"] as? [String: Any],
	let projectXcodeVersion = project["xcode_version"] as? String else {
		print("\(projectPath):1:1: error: Xcode Version not found in Config.json")
		exit(1)
}

let xcodeVersionCleaned = xcodeVersion.trimmingCharacters(in: .init(charactersIn: "0"))
let projectXcodeVersionCleaned = projectXcodeVersion.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .init(charactersIn: "0"))

let projectXcodeVersionMajorCleaned = projectXcodeVersion.split(separator: ".")[0].trimmingCharacters(in: .init(charactersIn: "0"))
let xcodeVersionMajorCleaned = xcodeVersionMajor.trimmingCharacters(in: .init(charactersIn: "0"))

if (projectXcodeVersionMajorCleaned != xcodeVersionMajorCleaned) {
	print("\(projectPath):1:1: error: Xcode Version does not match Config.json. Please use Xcode-\(projectXcodeVersion) or change Config.json")
	exit(1)
}

if (xcodeVersionCleaned != projectXcodeVersionCleaned) {
	print("\(projectPath):1:1: warning: Xcode Version does not match Config.json. Please consider using Xcode-\(projectXcodeVersion) or change Config.json")
	exit(0)
}

exit(0)
