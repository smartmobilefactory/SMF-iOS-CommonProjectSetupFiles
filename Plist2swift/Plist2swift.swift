//
//  main.swift
//  plist2swift
//
//  Created by Bartosz Swiatek on 12.09.18.
//  Copyright © 2018 Bartosz Swiatek. All rights reserved.
//
// Note: Currently Date is not supported

import Foundation

// MARK: Defaults

let configurationKeyName: String = "configurationName"
var output: FileHandle? = FileHandle.standardOutput
var countOfTabs = 0

// MARK: Helper

private func usage() {
	let executableName = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
	print("""
		plist2swift code generator

		Usage: \(executableName) -e enumName [-o outputFile] plist1 plist2 ...

		i.e. \(executableName) -e Api /path/to/production-configuration.plist /path/to/development-configuration.plist > generated.swift
		i.e. \(executableName) -e Api -o generated.swift /path/to/production-configuration.plist /path/to/development-configuration.plist
		""")
	exit(1)
}

private func tabs(intendBy: Int = 0) -> String {
	var tabsString = ""

	intend(by: intendBy)

	for _ in 0..<countOfTabs {
		tabsString += "\t"
	}

	return tabsString
}

private func intend(by indentationLevel: Int = 1) {
	countOfTabs += indentationLevel
}

/**
Given path to .plist file, it returns a sorted array of tuples

- Parameter fromPath: Path to the .plist file

- Returns: sorted array of tuples of type (key: String, value: Any)
*/
private func readPlist(fromPath: String) -> KeyValueTuples? {
	var format = PropertyListSerialization.PropertyListFormat.xml

	guard
		let plistData = FileManager.default.contents(atPath: fromPath),
		let plistDict = try! PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &format) as? [String: Any] else {
			return nil
	}

	let tupleArray = plistDict.sorted { (pairOne, pairTwo) -> Bool in
		return pairOne.key < pairTwo.key
	}

	return KeyValueTuples(tuples: tupleArray)
}

/**
Generates the Swift header with date
*/
private func generateHeader() {
	print("""
		//
		// Generated by plist2swift - Swift code from plists generator
		//

		import Foundation

		""")
}

/**
Checking the key is present in the Optional Dictionary
*/
private func isKeyPresentInOptionalDictionary(keyToSearch: String, tupleKey: String, optionalDictionary: [String: [String: String]]) -> Bool {
	guard let optionalKeysAndTypes = optionalDictionary[keyToSearch] else {
		return false
	}

	let optionalArray = optionalKeysAndTypes.keys
	return optionalArray.contains(tupleKey)
}

/**
Checking the key is present in  all the plists
*/
private func isKeyAvailableInAllPlists(keyToSearch: String, tupleKey: String, tuplesForPlists: [String: KeyValueTuples]) -> Bool {
	let plistPaths = tuplesForPlists.keys
	for plistPath in plistPaths {

		guard let tuples = tuplesForPlists[plistPath] else {
			return false
		}

		guard let dictionary = tuples[tupleKey] as? Dictionary<String, Any> else {
			return false
		}

		if (dictionary.keys.contains(keyToSearch) == false) {
				return false
		}
	}

	return true
}

/**
Generate Protocol for the Tuples and return the optional dictionary
*/
private func generateProtocol(tuplesForPlists: [String: KeyValueTuples], allKeyValueTuples: [String: KeyValueTuples]) -> [String: [String: String]] {
	var optionalDictionary: [String: [String: String]] = [:]
	for (tupleKey, tuples) in allKeyValueTuples {

		let name = tupleKey.uppercaseFirst()
		let protocolName = name.appending("Protocol")
		print("protocol \(protocolName) {")
		intend()

		var optionalKeysAndTypes: [String: String] = [:]
		for tuple in tuples.tuples {
			let isOptional = !(isKeyAvailableInAllPlists(keyToSearch: tuple.key, tupleKey: tupleKey, tuplesForPlists: tuplesForPlists))
			var type = typeForValue(tuple.value as Any)
			if (isOptional == true) {
				type = "\(type)?"
				optionalKeysAndTypes[tuple.key] = type
			}

			print("\(tabs())var \(tuple.key.lowercaseFirst()): \(type) { get }")
		}

		optionalDictionary[tupleKey] = optionalKeysAndTypes
		print("\(tabs(intendBy: -1))}\n")
	}

	return optionalDictionary
}

/**
Generates a protocol with public instance properties. Used to generate protocols that internal structs conform to.

- Parameter name: Name of the protocol; "Protocol" will be added to the name as suffix
- Parameter tuples: Key Value Tuples to create protocol from

- Returns: Protocol name, in case it's needed to be saved for further use
*/
private func generateProtocol(name: String, tuples: KeyValueTuples) -> String {

	let protocolName = name.appending("Protocol")
	print("protocol \(protocolName) {")
	intend()

	for tuple in tuples.tuples {
		let type = typeForValue(tuple.value as Any)
		print("\(tabs())var \(tuple.key.lowercaseFirst()): \(type) { get }")
	}

	print("\(tabs(intendBy: -1))}\n")
	return protocolName
}

/**
Generate the general protocol with class properties.

- Parameter name: Name of the protocol; "Protocol" will be added to the name as suffix
- Parameter commonKeys: Keys to generate non-Optional properties from
- Parameter oddKeys: Keys to generate Optional properties from
- Parameter keysAndTypes: Map with keys and their types

*/
private func generateProtocol(name: String, commonKeys: [String], oddKeys: [String], keysAndTypes: [String:String]) {
	print("\(tabs())protocol \(name) {")
	intend()
	print("\(tabs())// Common Keys")

	for commonKey in commonKeys {

		guard let type = keysAndTypes[commonKey] else {
			return
		}

		print("\(tabs())var \(commonKey.lowercaseFirst()): \(type) { get }")
	}

	if (!oddKeys.isEmpty) {

		print("\n\(tabs())// Optional Keys")

		for oddKey in oddKeys {

			guard let type = keysAndTypes[oddKey] else {
				return
			}

			print("\(tabs())var \(oddKey.lowercaseFirst()): \(type)? { get }")
		}
	}

	print("\(tabs(intendBy: -1))}\n")
}

/**
Generate structs out of Dictionaries and make them conform to a given protocol.

- Parameters:
- name: Name of the struct. Default is 'nil' - the configurationName key will be used to generate the name
- tuples: Key Value Tuples to create protocol from
- keysAndTypes: Map with keys and their types; Default is 'nil' - A new protocol will be created, the generated struct will conform to this new protocol
- oddKeys: Keys to generate Optional properties from
- protocolName: Name of the protocol; It has to end with a "Protocol" suffix; Default is 'nil' - the new generated protocol will be used

*/
private func generateStructs(name key: String? = nil, tuples: KeyValueTuples, keysAndTypes: [String: String]? = nil, oddKeys: [String], protocolName: String? = nil, optionalDictionary: [String: [String: String]]) {
	var configName: String? = tuples[configurationKeyName] as? String

	if (configName == nil && key != nil) {
		configName = key
	}

	guard var structName = configName else {
		return
	}

	structName = structName.uppercaseFirst()

	var localKeysAndTypes = keysAndTypes

	if (localKeysAndTypes == nil) {
		localKeysAndTypes = [:]

		for tuple in tuples.tuples {
			let key = tuple.key
			let value = tuple.value

			if (localKeysAndTypes?[key] == nil) {
				let type = typeForValue(value)
				localKeysAndTypes?[key] = type

				// Generate protocols for Dictionary entries
				if (type == "Dictionary<String, Any>") {
					let dictionary = tuples[key] as? Dictionary<String, Any>
					let sortedDictionary = dictionary?.sorted { (pairOne, pairTwo) -> Bool in
						return pairOne.key < pairTwo.key
					}

					let protocolName = generateProtocol(name: key.uppercaseFirst(), tuples: KeyValueTuples(tuples: sortedDictionary ?? []))
					// override type with new protocol
					localKeysAndTypes?[key] = protocolName
				}
			}
		}
	}

	var conformingToProtocol: String = ""

	if (protocolName != nil) {
		conformingToProtocol = ": ".appending(protocolName!)
	}

	print("\n\(tabs())internal struct \(structName)\(conformingToProtocol) {")
	intend()

	var availableKeys: [String] = []
	for tuple in tuples.tuples {

		let tupleKey = tuple.key
		let tupleValue = tuple.value
		availableKeys.append(tupleKey)

		if (oddKeys.contains(tupleKey)) {
			continue
		}

		guard let type = localKeysAndTypes?[tupleKey] else {
			return
		}

		let isOptional: Bool = {
			guard let key = key else {
				return false
			}

			return isKeyPresentInOptionalDictionary(keyToSearch: key, tupleKey: tupleKey, optionalDictionary: optionalDictionary)
		}()

		switch type {
		case "String" where (isOptional == false):
			print("\(tabs())internal let \(tupleKey.lowercaseFirst()): \(type) = \"\(tupleValue)\"")
		case "String" where (isOptional == true):
			print("\(tabs())internal var \(tupleKey.lowercaseFirst()): \(type)? = \"\(tupleValue)\"")
		case "Int" where (isOptional == false):
			print("\(tabs())internal let \(tupleKey.lowercaseFirst()): \(type) = \(tupleValue)")
		case "Int" where (isOptional == true):
			print("\(tabs())internal var \(tupleKey.lowercaseFirst()): \(type)? = \(tupleValue)")
		case "Bool" where (isOptional == false):
			let boolString = (((tupleValue as? Bool) == true) ? "true" : "false")
			print("\(tabs())internal let \(tupleKey.lowercaseFirst()): \(type) = \(boolString)")
		case "Bool" where (isOptional == true):
			let boolString = (((tupleValue as? Bool) == true) ? "true" : "false")
			print("\(tabs())internal var \(tupleKey.lowercaseFirst()): \(type)? = \(boolString)")
		case "Array<Any>" where (isOptional == false):
			let arrayValue = tupleValue as! Array<String>
			print("\(tabs())internal let \(tupleKey.lowercaseFirst()): \(type) = \(arrayValue)")
		case "Array<Any>" where (isOptional == true):
			let arrayValue = tupleValue as! Array<String>
			print("\(tabs())internal var \(tupleKey.lowercaseFirst()): \(type)? = \(arrayValue)")
		default:
			// default is a struct
			// Generate struct from the Dictionaries and Protocols
			if (type.contains("Protocol")) {
				let dictionary = tuples[tupleKey] as? Dictionary<String, Any>
				let sortedDictionary = dictionary?.sorted { (pairOne, pairTwo) -> Bool in
					return pairOne.key < pairTwo.key
				}

				generateStructs(name: tupleKey, tuples: KeyValueTuples(tuples: sortedDictionary ?? []), oddKeys: oddKeys, protocolName: type, optionalDictionary: optionalDictionary)

				print("\(tabs())internal let \(tupleKey.lowercaseFirst()): \(type) = \(tupleKey.uppercaseFirst())()")
			}

		}
	}

	guard let key = key, let optionalKeysAndTypes = optionalDictionary[key] else {
		print("\(tabs(intendBy: -1))}\n")
		return
	}

	let keysAndTypesToAdd = optionalKeysAndTypes.filter { (key: String, type: String) in
		return (availableKeys.contains(key) == false)
	}

	for (key, type) in keysAndTypesToAdd {
		print("\(tabs())internal var \(key.lowercaseFirst()): \(type) = nil")
	}

	print("\(tabs(intendBy: -1))}\n")
}

/**
Generates extensions to structs, conforming to protocol

- Parameters:
- enumName: Name of the enum containing structs that need to conform to given protocol
- protocolName: Name of the protocol to conform to
- allTuples: List of Key Value Tuples serialized from plist files
- keysAndTypes: Map with keys and their types
- oddKeys: Keys to generate Optional properties from

*/
private func generateExtensions(enumName: String, protocolName: String, allTuples: [KeyValueTuples], keysAndTypes: Dictionary<String, String>, oddKeys: [String], optionalDictionary: [String: [String: String]]) {
	for tuples in allTuples {

		guard let caseName = tuples[configurationKeyName] as? String else {
			return
		}

		let structName = caseName.uppercaseFirst()

		print("\(tabs())extension \(enumName).\(structName): \(protocolName) {")
		intend()

		for oddKey in oddKeys {

			guard let type = keysAndTypes[oddKey] else {
				return
			}

			if (type == "Array<Any>") {
				print("\(tabs())var \(oddKey.lowercaseFirst()): \(type)? {")

				let returnValue = tuples[oddKey] as? Array<String>

				((returnValue != nil) ? print("\(tabs())return \(returnValue!)") : print("\t\treturn nil"))
				print("\(tabs())}")
			} else if (type.contains("Protocol")){
				guard tuples[oddKey] != nil else {
					print("\(tabs())var \(oddKey.lowercaseFirst()): \(type)? {")
					print("\(tabs(intendBy: 1))return nil")
					print("\(tabs(intendBy: -1))}")
					continue
				}

				let dictionary = tuples[oddKey] as? Dictionary<String, Any>
				let sortedDictionary = dictionary?.sorted { (pairOne, pairTwo) -> Bool in
					return pairOne.key < pairTwo.key
				}

				generateStructs(name: oddKey, tuples: KeyValueTuples(tuples: sortedDictionary ?? []), oddKeys: oddKeys, protocolName: type, optionalDictionary: optionalDictionary)
				print("\(tabs())var \(oddKey.lowercaseFirst()): \(type)? {")
				print("\(tabs(intendBy: 1))return \(oddKey.uppercaseFirst())()")
				print("\(tabs(intendBy: -1))}")
			} else { // String
				print("\(tabs())var \(oddKey.lowercaseFirst()): \(type)? {")
				intend()
				let returnValue = tuples[oddKey] as? String
				returnValue != nil ? print("\(tabs())return \"\(returnValue!)\"") : print("\(tabs())return nil")
				print("\(tabs(intendBy: -1))}")
			}
		}
		print("\(tabs(intendBy: -1))}\n")
	}
}

/**
Generate an enum with structs and properties.

- Parameters:
- name: Name of the enum
- protocolName: Name of the protocol that extensions should conform to
- allTuples: List of Key Value Tuples serialized from plist files
- keysAndTypes: Map with keys and their types
- oddKeys: Keys to generate Optional properties from

*/
private func generateEnum(name enumName: String, protocolName: String, allTuples: [KeyValueTuples], keysAndTypes: Dictionary<String, String>, oddKeys: [String], optionalDictionary: [String: [String: String]]) {

	let cases: [String] = allTuples.map { (tuples: KeyValueTuples) in
		return (tuples[configurationKeyName] as? String ?? "")
	}

	print("\(tabs())internal enum \(enumName) {")
	intend()

	for caseName in cases {
		print("\(tabs())case \(caseName.lowercaseFirst())")
	}

	for tuples in allTuples {
		generateStructs(tuples: tuples, keysAndTypes: keysAndTypes, oddKeys: oddKeys, optionalDictionary: optionalDictionary)
	}

	print("""
		\(tabs())var configuration: \(protocolName) {

		\(tabs(intendBy: 1))switch self {
		""")

	for caseName in cases {
		let structName = caseName.uppercaseFirst()
		print("\(tabs())case .\(caseName.lowercaseFirst()):")
		print("\(tabs())\treturn \(structName)()")
	}

	print("\(tabs())}")
	print("\(tabs(intendBy: -1))}")
	print("\(tabs(intendBy: -1))}\n")
	generateExtensions(enumName: enumName, protocolName: protocolName, allTuples: allTuples, keysAndTypes: keysAndTypes, oddKeys: oddKeys, optionalDictionary: optionalDictionary)
}

/**
Map the type of a value to its string representation

- Parameter value: Any object you want to get the string type equivalent from; default is "String". Supported types are: String, Bool, Int, Array<Any> and Dictionary<String, Any>

- Returns: String that reflects the type of given value
*/
private func typeForValue(_ value: Any) -> String {
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

// MARK: Logging

extension FileHandle: TextOutputStream {
	public func write(_ string: String) {
		guard let data = string.data(using: .utf8) else {
			return
		}

		self.write(data)
	}
}

public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
	let localOutput = items.map { "\($0)" }.joined(separator: separator)

	guard var output = output else {
		return
	}

	Swift.print(localOutput, separator: separator, terminator: terminator, to: &output)
}

// MARK: String

extension String {
	func uppercaseFirst() -> String {
		return prefix(1).uppercased() + dropFirst()
	}

	func lowercaseFirst() -> String {
		return prefix(1).lowercased() + dropFirst()
	}

	mutating func uppercaseFirst() {
		self = self.uppercaseFirst()
	}

	mutating func lowercaseFirst() {
		self = self.lowercaseFirst()
	}
}

// MARK: - Tuples

class KeyValueTuples {

	var tuples: [(key: String, value: Any)]

	var keys: [String] {
		let keys = self.tuples.map { (tuple: (key: String, value: Any)) in
			return tuple.key
		}

		return keys
	}

	init(tuples: [(key: String, value: Any)]) {
		self.tuples = tuples
	}

	subscript(_ key: String) -> Any? {
		get {
			let tuple = self.tuples.first { (tuple: (key: String, value: Any)) -> Bool in
				return tuple.key == key
			}

			return tuple?.value
		}
	}
}

// MARK: Main

let args = CommandLine.arguments
var plists: [String] = []
var enumName: String = ""

if (args.count < 4) {
	usage()
}

if (args.count >= 6 && args[1] == "-e" && args[3] == "-o") {
	enumName = args[2]

	let fileManager = FileManager.default

	if (fileManager.fileExists(atPath: args[4]) == true) {
		try? fileManager.removeItem(atPath: args[4])
	}

	fileManager.createFile(atPath: args[4], contents: nil, attributes: nil)

	output = FileHandle(forWritingAtPath: args[4])

	for i in 5...args.count-1 {
		plists.append(args[i])
	}
} else if (args.count >= 4 && args[1] == "-e") {
	enumName = args[2]

	for i in 3...args.count-1 {
		plists.append(args[i])
	}
} else {
	usage()
}

let shouldGenerateOddKeys: Bool = CommandLine.arguments.count >= 5
var commonKeys = [String]()
var oddKeys = [String]()
var keysAndTypes: [String:String] = [:]
var allTuples: [KeyValueTuples] = []
var protocolName: String = enumName.appending("Protocol")
var tuplesForPlists: [String: KeyValueTuples] = [:]
var allKeyValueTuples: [String: KeyValueTuples] = [:]
generateHeader()

// gather keys and values... and types
for plistPath in plists {

	guard let tuples = readPlist(fromPath: plistPath) else {
		print("Couldn't read plist at \(plistPath)")
		exit(1)
	}

	tuplesForPlists[plistPath] = tuples
	allTuples.append(tuples)

	let allKeys = tuples.keys

	if (allKeys.contains(configurationKeyName) == false) {
		print("Plist doesn't contain \(configurationKeyName) key. Please add it and run the script again")
		exit(1)
	}

	if (commonKeys.count == 0) {
		commonKeys = allKeys
	}

	if (oddKeys.count == 0 && shouldGenerateOddKeys) {
		oddKeys = allKeys
	}

	for key in allKeys {
		if (keysAndTypes[key] == nil) {
			let type = typeForValue(tuples[key]!)
			keysAndTypes[key] = type
			// Generate protocols for Dictionary entries
			if (type == "Dictionary<String, Any>") {

				let dictionary = tuples[key] as? Dictionary<String, Any>
				let sortedDictionary = dictionary?.sorted { (pairOne, pairTwo) -> Bool in
					return pairOne.key < pairTwo.key
				}

				allKeyValueTuples[key] = KeyValueTuples(tuples: sortedDictionary ?? [])
				let name = key.uppercaseFirst()
				let protocolName = name.appending("Protocol")
				keysAndTypes[key] = protocolName
			}
		}
	}

	commonKeys = Array(Set(commonKeys).intersection(allKeys)).sorted()
	oddKeys = Array(Set(oddKeys).union(allKeys)).sorted()
	oddKeys = Array(Set(oddKeys).subtracting(commonKeys)).sorted()

	if (oddKeys.count == 0 && shouldGenerateOddKeys && plists.count > 1 && plists.firstIndex(of: plistPath) == 0) {
		oddKeys = allKeys
	}
}

let optionalDictionary = generateProtocol(tuplesForPlists: tuplesForPlists, allKeyValueTuples: allKeyValueTuples)
generateProtocol(name: protocolName, commonKeys: commonKeys, oddKeys: oddKeys, keysAndTypes: keysAndTypes)
generateEnum(name: enumName, protocolName: protocolName, allTuples: allTuples, keysAndTypes: keysAndTypes, oddKeys: oddKeys, optionalDictionary: optionalDictionary)
