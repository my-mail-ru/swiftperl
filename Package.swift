import PackageDescription
import Glibc

let package = Package(
	name: "CPerl"
)

func getenv(_ name: String) -> String? {
	guard let value = Glibc.getenv(name) else { return nil }
	return String(cString: value)
}

// Taken from swift-package-manager
let tmpdir = getenv("TMPDIR") ?? getenv("TEMP") ?? getenv("TMP") ?? "/tmp/"

let me = CommandLine.arguments[0]
if me[me.startIndex..<min(me.endIndex, tmpdir.endIndex)] != tmpdir {
	var parts = me.characters.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
	parts[parts.endIndex - 1] = "generate-modulemap"
	let command = parts.joined(separator: "/")

	guard system(command) == 0 else {
		fatalError("Failed to execute \(command)")
	}
}
