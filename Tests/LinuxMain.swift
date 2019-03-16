import XCTest

import cli_mateTests

var tests = [XCTestCaseEntry]()
tests += cli_mateTests.allTests()
XCTMain(tests)