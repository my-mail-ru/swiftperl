import CPerl

protocol PerlObjectType : PerlSVProbablyConvertible {
	var sv: PerlSV { get }
	static var perlClassName: String { get }
	init(_: PerlSV)
}

extension PerlObjectType {
	static func loadModule(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		perl.pointee.loadModule(perlClassName)
	}
}

extension PerlInterpreter {
	static var classMapping = [String: PerlObjectType.Type ]()

	static func register(_ swiftClass: PerlObjectType.Type) {
		classMapping[swiftClass.perlClassName] = swiftClass
	}
}
