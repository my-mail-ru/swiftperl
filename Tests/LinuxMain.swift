import XCTest

@testable import PerlTests

var tests = [XCTestCaseEntry]()
tests += [testCase(EmbedTests.allTests)]
tests += [testCase(ConvertFromPerlTests.allTests)]
tests += [testCase(ConvertToPerlTests.allTests)]
tests += [testCase(ObjectTests.allTests)]
tests += [testCase(BenchmarkTests.allTests)]
XCTMain(tests)
