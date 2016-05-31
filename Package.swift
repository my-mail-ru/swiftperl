import PackageDescription

let package = Package(
	name: "SwiftPerl",
	targets: [
		Target(name: "CPerl"),
		Target(name: "Perl", dependencies: [.Target(name: "CPerl")])
	]
)

products.append(Product(name: "SwiftPerl", type: .Library(.Dynamic), modules: "Perl"))
