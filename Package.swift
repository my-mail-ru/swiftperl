import PackageDescription
import Glibc

let package = Package(
	name: "Perl",
	targets: [
		Target(name: "CPerl"),
		Target(name: "Perl", dependencies: [.Target(name: "CPerl")]),
		Target(name: "SampleXS", dependencies: [.Target(name: "Perl")])
	]
)

products.append(Product(name: "SampleXS", type: .Library(.Dynamic), modules: "SampleXS"))

let me = CommandLine.arguments[0]
var parts = me.characters.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
parts[parts.endIndex - 1] = "prepare"
let command = parts.joined(separator: "/")

guard system(command) == 0 else {
	fatalError("Failed to execute \(command)")
}
