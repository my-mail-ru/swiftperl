import PackageDescription

#if os(Linux) || os(FreeBSD) || os(PS4) || os(Android) || CYGWIN
import Glibc
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
#endif

let packageDir: String = {
	let me = CommandLine.arguments[0]
	var parts = me.characters.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
	parts[parts.endIndex - 1] = ""
	return parts.joined(separator: "/")
}()

let package = Package(
	name: "CPerl",
	pkgConfig: "../../.." + packageDir + "libperl"
)

func env(_ name: String) -> String? {
	guard let value = getenv(name) else { return nil }
	return String(cString: value)
}

let tmpdir = env("TMPDIR") ?? env("TEMP") ?? env("TMP") ?? "/tmp/"

if packageDir[packageDir.startIndex..<min(packageDir.endIndex, tmpdir.endIndex)] != tmpdir {
	let command = packageDir + "prepare"

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
