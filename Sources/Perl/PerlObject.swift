import CPerl

class PerlObject : PerlValue, PerlDerived {
	typealias UnsafeValue = UnsafeSV

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		guard sv.pointee.isObject(perl: perl) else {
			throw PerlError.notObject(fromUnsafeSvPointer(noinc: sv, perl: perl))
		}
		if let named = type(of: self) as? PerlNamedClass.Type {
			guard sv.pointee.isDerived(from: named.perlClassName, perl: perl) else {
				throw PerlError.unexpectedObjectType(fromUnsafeSvPointer(noinc: sv, perl: perl), want: type(of: self))
			}
		}
		self.init(noincUnchecked: sv, perl: perl)
	}

	convenience init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(inc: usv, perl: perl)
	}

	var perlClassName: String {
		return withUnsafeSvPointer { sv, perl in sv.pointee.classname(perl: perl)! }
	}

	var referent: AnyPerl {
		return withUnsafeSvPointer { sv, perl in fromUnsafeSvPointer(inc: sv.pointee.referent!, perl: perl) }
	}

	override var debugDescription: String {
		var rvDesc = ""
		debugPrint(referent, terminator: "", to: &rvDesc)
		return "\(type(of: self))(\(perlClassName), rv=\(rvDesc))"
	}

	static func derivedClass(for classname: String) -> PerlObject.Type {
		return PerlInterpreter.classMapping[classname] ?? PerlObject.self
	}
}

protocol PerlBridgedObject : AnyPerl, PerlNamedClass, PerlSvConvertible {}

protocol PerlNamedClass : class {
	static var perlClassName: String { get }
}

extension PerlNamedClass {
	static func loadModule(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		perl.pointee.loadModule(perlClassName)
	}
}

extension PerlNamedClass where Self : PerlObject {
	init(method: String, args: [PerlSvConvertible?], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		perl.pointee.enterScope()
		defer { perl.pointee.leaveScope() }
		let classname = (type(of: self) as PerlNamedClass.Type).perlClassName
		let args = [classname as PerlSvConvertible?] + args
		let svArgs: [UnsafeSvPointer] = args.map { $0?.toUnsafeSvPointer(perl: perl) ?? perl.pointee.newSV() }
		let sv = try perl.pointee.unsafeCall(sv: perl.pointee.newSV(method, mortal: true), args: svArgs, flags: G_METHOD|G_SCALAR)[0]
		guard sv.pointee.isObject(perl: perl) else {
			throw PerlError.notObject(fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		guard sv.pointee.isDerived(from: classname, perl: perl) else {
			throw PerlError.unexpectedObjectType(fromUnsafeSvPointer(inc: sv, perl: perl), want: Self.self)
		}
		self.init(incUnchecked: sv, perl: perl)
	}
}

extension PerlInterpreter {
	static var classMapping = [String: PerlObject.Type ]()

	static func register<T>(_ swiftClass: T.Type) where T : PerlObject, T : PerlNamedClass {
		classMapping[(swiftClass as PerlNamedClass.Type).perlClassName] = swiftClass
	}
}
