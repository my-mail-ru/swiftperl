import PackageDescription
import Glibc

let buildBenchmark = false

let package = Package(
	name: "Perl",
	targets: [
		Target(name: "Perl"),
	],
	dependencies: [
		.Package(url: "https://github.com/my-mail-ru/swift-CPerl.git", versions: Version(0, 1, 1)..<Version(0, .max, .max)),
	]
)

if buildBenchmark {
	package.targets.append(Target(name: "swiftperl-benchmark", dependencies: [.Target(name: "Perl")]))
	package.dependencies.append(.Package(url: "https://github.com/my-mail-ru/swift-Benchmark.git", majorVersion: 0))
} else {
	package.exclude.append("Sources/swiftperl-benchmark")
}

func getenv(_ name: String) -> String? {
	guard let value = Glibc.getenv(name) else { return nil }
	return String(cString: value)
}

// Taken from swift-package-manager
let tmpdir = getenv("TMPDIR") ?? getenv("TEMP") ?? getenv("TMP") ?? "/tmp/"

let me = CommandLine.arguments[0]
if me[me.startIndex..<min(me.endIndex, tmpdir.endIndex)] != tmpdir {
	var parts = me.characters.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
	parts[parts.endIndex - 1] = "prepare"
	let command = parts.joined(separator: "/")

	guard system(command) == 0 else {
		fatalError("Failed to execute \(command)")
	}
}
