import Benchmark
import Perl

func run(_ code: String, count: Int = 1000000) {
	let sample = benchmark { try! perl.eval("\(code) for (1..\(count));") }
	print("\"\(code)\",\(sample.cpu)")
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
