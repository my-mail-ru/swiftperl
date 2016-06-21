import XCTest

@testable import PerlTestSuite
@testable import PerlCoroTestSuite

var tests = [XCTestCaseEntry]()
tests += [testCase(EmbedTests.allTests)]
tests += [testCase(BasicTests.allTests)]
tests += [testCase(ObjectTests.allTests)]
tests += [testCase(BenchmarkTests.allTests)]
tests += [testCase(CoroTests.allTests)]
XCTMain(tests)
