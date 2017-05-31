import Benchmark
import Perl

func run(_ code: String, count: Int = 1000000) {
	let sample = benchmark { try! perl.eval("\(code) for (1..\(count));") }
	print("\"\(code)\",\(sample.cpu)")
}

func run(_ name: String, count: Int = 1000000, body: () -> Void) {
	let sample = benchmark(count: count, body)
	print("\"\(name)\",\(sample.cpu)")
}

final class TestObject : PerlObject, PerlNamedClass {
	static let perlClassName = "TestObject"
}

final class TestBridgedObject : PerlBridgedObject {
	static let perlClassName = "TestBridgedObject"
}

let perl = PerlInterpreter.new()
defer { perl.destroy() }

TestObject.register()
let obj: PerlObject = try! perl.eval("bless {}, 'TestAnyObject'")
let subobj: TestObject = try! perl.eval("bless {}, 'TestObject'")

PerlSub(name: "void") { () -> Void in }

PerlSub(name: "in_int") { (_: Int) -> Void in }
PerlSub(name: "in_string") { (_: String) -> Void in }
PerlSub(name: "in_scalar") { (_: PerlScalar) -> Void in }
PerlSub(name: "in_object") { (_: PerlObject) -> Void in }
PerlSub(name: "in_subobject") { (_: TestObject) -> Void in }
PerlSub(name: "in_bridged_object") { (_: TestBridgedObject) -> Void in }

PerlSub(name: "in_arrint") { (_: [Int]) -> Void in }
PerlSub(name: "in_arrstring") { (_: [String]) -> Void in }
PerlSub(name: "in_arrscalar") { (_: [PerlScalar]) -> Void in }

PerlSub(name: "in_dictint") { (_: [String: Int]) -> Void in }
PerlSub(name: "in_dictstring") { (_: [String: String]) -> Void in }
PerlSub(name: "in_dictscalar") { (_: [String: PerlScalar]) -> Void in }

PerlSub(name: "out_int") { () -> Int in 10 }
PerlSub(name: "out_string") { () -> String in "string" }
PerlSub(name: "out_scalar") { () -> PerlScalar in PerlScalar() }
PerlSub(name: "out_object") { () -> PerlObject in obj }
PerlSub(name: "out_subobject") { () -> TestObject in subobj }
PerlSub(name: "out_bridged_object") { () -> TestBridgedObject in TestBridgedObject() }

PerlSub(name: "last_resort") { [try $0.get(0) as Int, try $0.get(1) as String] }

PerlSub(name: "lr_void") { (_: PerlSub.Args) in [] }

PerlSub(name: "lr_in_int") { (args: PerlSub.Args) in _ = try args.get(0) as Int; return [] }
PerlSub(name: "lr_in_string") { (args: PerlSub.Args) in _ = try args.get(0) as String; return [] }
PerlSub(name: "lr_in_scalar") { (args: PerlSub.Args) in _ = args[0]; return [] }
PerlSub(name: "lr_in_object") { (args: PerlSub.Args) in _ = try args.get(0) as PerlObject; return [] }
PerlSub(name: "lr_in_subobject") { (args: PerlSub.Args) in _ = try args.get(0) as TestObject; return [] }
PerlSub(name: "lr_in_bridged_object") { (args: PerlSub.Args) in _ = try args.get(0) as TestBridgedObject; return [] }

PerlSub(name: "lr_out_int") { _ in [10] }
PerlSub(name: "lr_out_string") { _ in ["string"] }
PerlSub(name: "lr_out_scalar") { _ in [PerlScalar()] }
PerlSub(name: "lr_out_object") { _ in [obj] }
PerlSub(name: "lr_out_subobject") { _ in [subobj] }
PerlSub(name: "lr_out_bridged_object") { _ in [TestBridgedObject()] }

run("void()")

run("in_int(10)")
run("in_string('строченька')")
run("in_string('ascii-string')")
run("in_scalar(undef)")
run("in_object(bless {}, 'TestAnyObject')")
run("in_subobject(bless {}, 'TestObject')")
run("in_object(bless {}, 'TestObject')")
try! perl.eval("$brobj = out_bridged_object()"); run("in_bridged_object($brobj)")

run("in_arrint(10)")
run("in_arrstring('строченька')")
run("in_arrstring('ascii-string')")
run("in_arrscalar(undef)")

run("in_dictint(k => 10)")
run("in_dictstring(k => 'строченька')")
run("in_dictstring(k => 'ascii-string')")
run("in_dictscalar(k => undef)")

run("out_int()")
run("out_string()")
run("out_scalar()")
run("out_object()")
run("out_subobject()")
run("out_bridged_object()")

run("last_resort(10, 'string')")

run("lr_void()")

run("lr_in_int(10)")
run("lr_in_string('ascii-string')")
run("lr_in_scalar(undef)")
run("lr_in_object(bless {}, 'TestAnyObject')")
run("lr_in_subobject(bless {}, 'TestObject')")
run("lr_in_object(bless {}, 'TestObject')")
try! perl.eval("$brobj = out_bridged_object()"); run("lr_in_bridged_object($brobj)")

run("lr_out_int()")
run("lr_out_string()")
run("lr_out_scalar()")
run("lr_out_object()")
run("lr_out_subobject()")
run("lr_out_bridged_object()")

try perl.eval("sub nop {}")
run("nop()") { try! perl.call(sub: "nop") }

let nop = PerlSub(get: "nop")!
run("$nop->()") { try! nop.call() }

try perl.eval("sub TestObject::nop {}")
run("TestObject->nop()") { try! TestObject.call(method: "nop") }
run("$obj->nop()") { try! subobj.call(method: "nop") }
