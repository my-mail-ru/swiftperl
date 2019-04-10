// swift-tools-version:5.0
import PackageDescription

#if os(Linux) || os(FreeBSD) || os(PS4) || os(Android) || CYGWIN
import Glibc
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

let buildBenchmark = false

let package = Package(
	name: "Perl",
	products: [
		.library(name: "Perl", targets: ["Perl"]),
	],
	dependencies: [
		.package(url: "https://github.com/my-mail-ru/swift-CPerl.git", from: "1.0.1"),
	],
	targets: [
		.target(name: "Perl"),
		.testTarget(name: "PerlTests", dependencies: ["Perl"]),
	]
)

if buildBenchmark {
	package.targets.append(.target(name: "swiftperl-benchmark", dependencies: ["Perl", "Benchmark"]))
	package.dependencies.append(.package(url: "https://github.com/my-mail-ru/swift-Benchmark.git", from: "0.3.1"))
}


func env(_ name: String) -> String? {
	guard let value = getenv(name) else { return nil }
	return String(cString: value)
}

let tmpdir = env("TMPDIR") ?? env("TEMP") ?? env("TMP") ?? "/tmp/"

let me = CommandLine.arguments[0]
if me[me.startIndex..<min(me.endIndex, tmpdir.endIndex)] != tmpdir {
	var parts = me.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
	parts[parts.endIndex - 1] = "prepare"
	let command = parts.joined(separator: "/")

	var pid = pid_t()
	command.withCString {
		guard posix_spawn(&pid, command, nil, nil, [UnsafeMutablePointer(mutating: $0), nil], nil) == 0 else {
			fatalError("Failed to spawn \(command)")
		}
	}
	var status: Int32 = 0
	guard waitpid(pid, &status, 0) != -1 else {
		fatalError("Failed to waitpid")
	}
	guard status == 0 else {
		fatalError("\(command) terminated with status \(status)")
	}
}
