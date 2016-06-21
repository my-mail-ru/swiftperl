import PackageDescription

let package = Package(
	name: "SwiftPerl",
	targets: [
		Target(name: "CPerl"),
		Target(name: "Perl", dependencies: [.Target(name: "CPerl")]),
		Target(name: "CPerlCoro"),
		Target(name: "PerlCoro", dependencies: [.Target(name: "Perl"), .Target(name: "CPerlCoro")]),
		Target(name: "SampleXS", dependencies: [.Target(name: "Perl")])
	]
)

products.append(Product(name: "SampleXS", type: .Library(.Dynamic), modules: "SampleXS"))
