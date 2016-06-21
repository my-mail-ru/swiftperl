import XCTest
import Foundation
@testable import Perl

class ObjectTests : EmbeddedTestCase {
	static var allTests: [(String, (ObjectTests) -> () throws -> Void)] {
		return [
			("testPerlObject", testPerlObject),
			("testSwiftObject", testSwiftObject),
			("testRefCnt", testRefCnt),
		]
	}

	func testPerlObject() throws {
		URI.loadModule()
		let uri = try URI("https://my.mail.ru/music")
		XCTAssertEqual(uri.path, "/music")
		uri.path = "/video"
		XCTAssertEqual(uri.asString, "https://my.mail.ru/video")
	}

	func testSwiftObject() throws {
		let url = NSURL(string: "https://my.mail.ru/music")!
		XCTAssertEqual(url.host, "my.mail.ru")
		NSURL.createPerlMethod("new") {
			(cname: String, str: String) -> NSURL in
			return NSURL(string: str)!
		}
		NSURL.createPerlMethod("host") {
			(obj: NSURL) -> String in
			return obj.host!
		}
		let host: String = try perl.eval("my $url = NSURL->new('https://my.mail.ru/music'); $url->host()")
		XCTAssertEqual(host, "my.mail.ru")
	}

	func testRefCnt() throws {
		TestRefCnt.createPerlMethod("new") { (cname: String) -> TestRefCnt in return TestRefCnt() }
		try perl.eval("TestRefCnt->new(); undef")
		XCTAssertEqual(TestRefCnt.refcnt, 0)
	}
}

extension NSURL : PerlMappedClass {
	static let perlClassName = "NSURL"
	static func cast(from sv: UnsafeSvPointer) throws -> Self {
		return try NSURL.tCast(from: sv)
	}
}

final class TestRefCnt : PerlMappedClass {
	static let perlClassName = "TestRefCnt"
	static var refcnt = 0
	init() { TestRefCnt.refcnt += 1 }
	deinit { TestRefCnt.refcnt -= 1 }
}
