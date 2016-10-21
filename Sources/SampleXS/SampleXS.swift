@testable import Perl

var perlInterpreter: PerlInterpreter!

@_cdecl("boot_SampleXS")
func boot(_ p: UnsafeInterpreterPointer) {
	print("OK")
	PerlCV(name: "Swift::test") {
		(stack: UnsafeXSubStack) in
		print("args: \(try stack.args.map { try String($0, perl: p) })")
		let result = PerlSV(MyTest()).toUnsafeSvPointer(perl: stack.perl)
		stack.xsReturn(CollectionOfOne(result))
	}
	MyTest.createPerlMethod("test") {
		(args: [PerlSV]) -> [PerlSV] in
//		let slf: MyTest = try! args[0].value()
//		slf.test(value: args[1].value())
//		slf.test2(value: try! args[2].value() as PerlTestMouse)
//		let bInt: PerlSV = 99
//		let bTrue: PerlSV = true
//		let arr: PerlAV = [1, 2, 3, 4, 5]
		return [101, "Строченька", nil, true, false, [8, [], "string"], ["key": "value", "k2": 34]]
//		return [[[1]]]
	}
	MyTest.createPerlMethod("test2") {
		(str: String) throws -> Int in
		throw PerlError.died(PerlSV("Throwing from Swift"))
	}
	PerlCV(name: "Swift::test_die") {
		(stack: UnsafeXSubStack) -> Void in
		do {
			try stack.perl.pointee.call(sub: "main::die_now")
		} catch PerlError.died(let err) {
			print("Perl died: \(try String(err))")
		} catch {
			print("Other error")
		}
		print("DONE")
	}
	PerlInterpreter.register(PerlTestMouse.self)
}

final class MyTest : PerlBridgedObject {
	static var perlClassName = "Swift::Perl.MyTest"
	var property = 15
	static var staticProperty = 500

	init () {
		print("##### INIT #####");
	}

	deinit {
		print("##### DEINIT #####");
	}

	func test(value: Int) {
		print("Method was called, property is \(property), value is \(value)")
//		let t = PerlTestMouse()
//		print("~~~~~~~~~ \(t.attr_ro)")
	}

	func test2 (value: PerlTestMouse) throws {
		print("test2: \(value.attr_rw) - \(value.attr_ro)")
		value.attr_rw = "Строка"
		print("array: \(value.list.count)")
		for v in value.list {
			print("value: \(try String(v))")
		}
		for (k, v) in value.hash {
			print("key: \(k), value: \(try String(v))")
		}
		print("key3: \(try String(value.hash["key3"]!))")
		print("do_something: \(try! value.doSomething(15, "more + "))")
		print("list: \(value.list)")
//		print("listOfStrings: \(value.listOfStrings)")
//		try! value.call(method: "unknown", args: 1, 2, "String")
	}
}

final class PerlTestMouse: PerlObject, PerlNamedClass {
	static let perlClassName = "TestMouse"

	var `attr_ro`: Int {
		get { return try! call(method: "attr_ro") }
	}
	var `attr_rw`: String {
		get { return try! call(method: "attr_rw") }
		set { try! call(method: "attr_rw", newValue) as Void }
	}
	var `maybe`: Int? {
		get { return try! call(method: "maybe") }
	}
	var `class`: String {
		get { return try! call(method: "class") }
	}
	var `maybe_class`: String? {
		get { return try! call(method: "maybe_class") }
	}
	var `list`: PerlAV {
		get { return try! call(method: "list") }
	}
	var `hash`: PerlHV {
		get { return try! call(method: "hash") }
	}
}

extension PerlTestMouse {
	func doSomething(_ v1: Int, _ v2: String) throws -> String {
		return try call(method: "do_something", v1, v2)
	}
	/* TODO:
	var `listOfStrings`: [String] {
		get { return try! call(method: "list") }
	}
	*/
}
