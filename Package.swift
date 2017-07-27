import PackageDescription

#if os(Linux) || os(FreeBSD) || os(PS4) || os(Android) || CYGWIN
import Glibc
#if os(Linux)
var environ: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> { return __environ }
#endif
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import Darwin
@_silgen_name("_NSGetEnviron")
func _NSGetEnviron() -> UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>>
var environ: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?> { return _NSGetEnviron().pointee }
#endif

let packageDir: String = {
	let me = CommandLine.arguments[0]
	var parts = me.characters.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
	parts[parts.endIndex - 1] = ""
	return parts.joined(separator: "/")
}()

#if swift(>=3.2)
let pkgConfig = "libperl"
#else
let pkgConfig = "../../.." + packageDir + "libperl"
#endif

let package = Package(
	name: "CPerl",
	pkgConfig: pkgConfig
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
		guard posix_spawn(&pid, command, nil, nil, [UnsafeMutablePointer(mutating: $0), nil], environ) == 0 else {
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
