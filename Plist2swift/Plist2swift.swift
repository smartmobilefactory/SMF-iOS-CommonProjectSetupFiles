//
//  main.swift
//  plist2swift
//
//  Created by Bartosz Swiatek on 12.09.18.
//  Copyright © 2018 Bartosz Swiatek. All rights reserved.
//
// Note: Currently only Strings, Bools and Ints and Dictionaries are supported

import Foundation

let configurationKeyName: String = "configurationName"

// MARK: Helper

private func usage() {
	print("""
		plist2swift code generator

		Usage: plist2swift plist1 plist2 ...

		i.e. plist2swift /path/to/production-configuration.plist /path/to/development-configuration.plist > generated.swift
	""")
	exit(1)
}

private func readPlist(fromPath: String) -> [String: AnyObject]? {
	var format = PropertyListSerialization.PropertyListFormat.xml
	guard let plistData = FileManager.default.contents(atPath: fromPath),
		let plistDict = try! PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &format) as? [String: AnyObject] else { return nil }

	return plistDict
}

private func generateHeader() {
	let date = Date()
	print("""
		//
		// Generated by plist2swift - Swift code from plists generator
		// (c) Smart Mobile Factory GmbH
		//
		// Generated on: \(date)
		//

		import Foundation

		""")
}

private func generateProtocol(name: String, commonKeys: Set<String>, oddKeys: Set<String>, keysAndTypes: Dictionary<String, String>) {
	print("protocol \(name) {")
	print("\t// Common Keys")
	for commonKey in commonKeys {
		let type = keysAndTypes[commonKey]
		print("\tstatic var \(commonKey): \(type!) { get }")
	}
	print("\t// Optional Keys")
	for oddKey in oddKeys {
		let type = keysAndTypes[oddKey]
		print("\tstatic var \(oddKey): \(type!)? { get }")
	}
	print("}")
	print("\n")
}

private func generateStructs(name protocolName: String, enumName: String, plistDict: Dictionary<String, AnyObject>, keysAndTypes: Dictionary<String, String>, oddKeys: Set<String>) {
	guard let configName = plistDict[configurationKeyName] as? String else { return }
	let structName = configName.appending("Struct")

	print("\tinternal struct \(structName) {")
	for (key, value) in plistDict {
		if (oddKeys.contains(key)) {
			continue
		}
		let type = keysAndTypes[key]
		switch type! {
		case "String":
			print("\t\tinternal static let \(key): \(type!) = \"\(value)\"")
		case "Int":
			print("\t\tinternal static let \(key): \(type!) = \(value)")
		case "Bool":
			let boolString = value.boolValue ? "true" : "false"
			print("\t\tinternal static let \(key): \(type!) = \(boolString)")
		case "Dictionary<String, Any>":
			let dictValue = value as! Dictionary<String, String>
			print("\t\tinternal static let \(key): \(type!) = \(dictValue)")
		default:
			print("\t\tinternal static let \(key): \(type!) = \"\(value)\"")
		}
	}
	print("\t}")
}

private func generateExtensions(enumName: String, cases: [String], protocolName: String, plistDicts: Array<Dictionary<String, AnyObject>>, keysAndTypes: Dictionary<String, String>, oddKeys: Set<String>) {
	for plistDict in plistDicts {
		guard let caseName = plistDict[configurationKeyName] as? String else { return }
		let structName = caseName.appending("Struct")
		print("extension \(enumName).\(structName): \(protocolName) {")
		for oddKey in oddKeys {
			let type = keysAndTypes[oddKey]
			print("\tstatic var \(oddKey): \(type!)? {")
			let returnValue = plistDict[oddKey] as? String
			returnValue != nil ? print("\t\treturn \"\(returnValue!)\"") : print("\t\treturn nil")
			print("\t}")
		}
		print("}\n")
	}
}

private func generateEnum(name enumName: String, protocolName: String, plistDicts: Array<Dictionary<String, AnyObject>>, keysAndTypes: Dictionary<String, String>, oddKeys: Set<String>) {
	var cases: [String] = []
	print("internal enum \(enumName) {")
	for plistDict in plistDicts {
		guard let caseName = plistDict[configurationKeyName] as? String else { return }
		cases.append(caseName.lowercased())
		// Cases
		print("\tcase \(caseName.lowercased())")
		generateStructs(name: protocolName, enumName: enumName, plistDict: plistDict, keysAndTypes: keysAndTypes, oddKeys: oddKeys)
	}
	print("""
		\n
		\tvar configuration: \(protocolName) {
			\tswitch self {
		""")
	for caseName in cases {
		print("\t\tcase .\(caseName):")
		print("\t\t\treturn \(caseName.capitalized)Struct()")
	}
	print("\t\t}")
	print("\t}")
	print("}\n")
	generateExtensions(enumName: enumName, cases: cases, protocolName: protocolName, plistDicts: plistDicts, keysAndTypes: keysAndTypes, oddKeys: oddKeys)
}

private func typeForValue(_ value: AnyObject) -> String {
	switch value {
	case is String:
		return "String"
	case is Bool:
		return "Bool"
	case is Int:
		return "Int"
	case is Array<Any>:
		return "Array<Any>"
	case is Dictionary<String, Any>:
		return "Dictionary<String, Any>"
	default:
		return "String"
	}
}

// MARK: Main

if (CommandLine.arguments.count < 2) {
	usage()
}

let shouldGenerateOddKeys: Bool = CommandLine.arguments.count >= 3

var plists: [String] = []
var commonKeys: Set<String> = Set()
var oddKeys: Set<String> = Set()
var keysAndTypes: [String:String] = [:]
var plistDicts: [Dictionary<String, AnyObject>] = []

for i in 1...CommandLine.arguments.count-1 {
	plists.append(CommandLine.arguments[i])
}

// gather keys and values... and types
for plistPath in plists {
	guard let plistDict = readPlist(fromPath: plistPath) else {
		print("Couldn't read plist at \(plistPath)")
		exit(1)
	}
	plistDicts.append(plistDict)

	let allKeys = Array(plistDict.keys)
	if (!allKeys.contains(configurationKeyName)) {
		print("Plist doesn't contain \(configurationKeyName) key. Please add it and run the script again")
		exit(1)
	}
	if (commonKeys.count == 0) {
		commonKeys = Set(allKeys)
	}
	if (oddKeys.count == 0 && shouldGenerateOddKeys) {
		oddKeys = Set(allKeys)
	}
	for key in allKeys {
		if (keysAndTypes[key] == nil) {
			keysAndTypes[key] = typeForValue(plistDict[key]!)
		}
	}
	commonKeys = commonKeys.intersection(allKeys)
	oddKeys = oddKeys.union(allKeys)
	oddKeys = oddKeys.subtracting(commonKeys)
	if (oddKeys.count == 0 && shouldGenerateOddKeys) {
		oddKeys = Set(allKeys)
	}
}

generateHeader()
generateProtocol(name: "SMFPlistProtocol", commonKeys: commonKeys, oddKeys: oddKeys, keysAndTypes: keysAndTypes)
generateEnum(name: "Api", protocolName: "SMFPlistProtocol", plistDicts: plistDicts, keysAndTypes: keysAndTypes, oddKeys: oddKeys)
