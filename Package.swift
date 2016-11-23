import PackageDescription

let package = Package(
	name: "Perl",
	targets: [
		Target(name: "CPerl"),
		Target(name: "Perl", dependencies: [.Target(name: "CPerl")]),
		Target(name: "SampleXS", dependencies: [.Target(name: "Perl")])
	]
)

products.append(Product(name: "SampleXS", type: .Library(.Dynamic), modules: "SampleXS"))
