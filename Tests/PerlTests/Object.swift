import XCTest
import Foundation
import Perl

class ObjectTests : EmbeddedTestCase {
	static var allTests: [(String, (ObjectTests) -> () throws -> Void)] {
		return [
			("testPerlObject", testPerlObject),
			("testSwiftObject", testSwiftObject),
			("testRefCnt", testRefCnt),
		]
	}

	func testPerlObject() throws {
		try URI.require()
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

final class URI : PerlObject, PerlNamedClass {
	static let perlClassName = "URI"

	convenience init(_ str: String) throws {
		try self.init(method: "new", args: [str])
	}

	convenience init(_ str: String, scheme: String) throws {
		try self.init(method: "new", args: [str, scheme])
	}

	convenience init(copyOf uri: URI) {
		try! self.init(uri.call(method: "clone") as PerlScalar)
	}

	var scheme: String? { return try! call(method: "scheme") }
	func scheme(_ scheme: String) throws -> String? { return try call(method: "scheme", scheme) }

	var path: String {
		get { return try! call(method: "path") }
		set { try! call(method: "path", newValue) as Void }
	}

	var asString: String { return try! call(method: "as_string") }

	func abs(base: String) -> String { return try! call(method: "abs", base) }
	func rel(base: String) -> String { return try! call(method: "rel", base) }

	var secure: Bool { return try! call(method: "secure") }
}

extension NSURL : PerlBridgedObject {
	public static let perlClassName = "NSURL"
}

final class TestRefCnt : PerlBridgedObject {
	static let perlClassName = "TestRefCnt"
	static var refcnt = 0
	init() { TestRefCnt.refcnt += 1 }
	deinit { TestRefCnt.refcnt -= 1 }
}
