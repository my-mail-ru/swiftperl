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

let perl = PerlInterpreter.new()
defer { perl.destroy() }

PerlSub(name: "void") { () -> Void in }

PerlSub(name: "in_int") { (_: Int) -> Void in }
PerlSub(name: "in_string") { (_: String) -> Void in }
PerlSub(name: "in_scalar") { (_: PerlScalar) -> Void in }

PerlSub(name: "in_arrint") { (_: [Int]) -> Void in }
PerlSub(name: "in_arrstring") { (_: [String]) -> Void in }
PerlSub(name: "in_arrscalar") { (_: [PerlScalar]) -> Void in }

PerlSub(name: "in_dictint") { (_: [String: Int]) -> Void in }
PerlSub(name: "in_dictstring") { (_: [String: String]) -> Void in }
PerlSub(name: "in_dictscalar") { (_: [String: PerlScalar]) -> Void in }

PerlSub(name: "out_int") { () -> Int in 10 }
PerlSub(name: "out_string") { () -> String in "string" }
PerlSub(name: "out_scalar") { () -> PerlScalar in PerlScalar() }

PerlSub(name: "last_resort") { [try $0.get(0) as Int, try $0.get(1) as String] }

PerlSub(name: "lr_void") { (_: PerlSub.Args) in [] }

PerlSub(name: "lr_in_int") { (args: PerlSub.Args) in _ = try args.get(0) as Int; return [] }
PerlSub(name: "lr_in_string") { (args: PerlSub.Args) in _ = try args.get(0) as String; return [] }
PerlSub(name: "lr_in_scalar") { (args: PerlSub.Args) in _ = args[0]; return [] }

PerlSub(name: "lr_out_int") { _ in [10] }
PerlSub(name: "lr_out_string") { _ in ["string"] }
PerlSub(name: "lr_out_scalar") { _ in [PerlScalar()] }

run("void()")

run("in_int(10)")
run("in_string('строченька')")
run("in_string('ascii-string')")
run("in_scalar(undef)")

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

run("last_resort(10, 'string')")

run("lr_void()")

run("lr_in_int(10)")
run("lr_in_string('ascii-string')")
run("lr_in_scalar(undef)")

run("lr_out_int()")
run("lr_out_string()")
run("lr_out_scalar()")

try perl.eval("sub nop {}")
run("nop()") { try! perl.call(sub: "nop") }

let nop = PerlSub(get: "nop")!
run("$nop->()") { try! nop.call() }

final class Test : PerlNamedClass {
	static var perlClassName = "Test"
}

try perl.eval("sub Test::nop {}")
run("Test->nop()") { try! Test.call(method: "nop") }

let obj: PerlObject = try perl.eval("bless {}, 'Test'")
run("$obj->nop()") { try! obj.call(method: "nop") }
