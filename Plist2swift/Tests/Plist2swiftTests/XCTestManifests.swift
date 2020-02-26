import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Plist2swiftTests.allTests),
    ]
}
#endif
