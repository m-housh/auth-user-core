import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AuthUser3Tests.allTests),
    ]
}
#endif