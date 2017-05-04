import CPerl

/// Provides a safe wrapper for Perl objects (blessed references).
/// Performs reference counting on initialization and deinitialization.
///
/// Any Perl object of unregistered type will be imported to Swift
/// as an instance of this class. To provide clean API to your
/// Perl object implement class derived from `PerlObject`, make it
/// conforming to `PerlNamedClass` and supply it with methods and
/// calculated attributes providing access to Perl methods of your
/// object. Use `register` method on startup to enable automatical
/// conversion of Perl objects of class `perlClassName` to instances
/// of your Swift class.
///
/// For example:
///
/// ```swift
/// final class URI : PerlObject, PerlNamedClass {
/// 	static let perlClassName = "URI"
/// 
/// 	convenience init(_ str: String) throws {
/// 		try self.init(method: "new", args: [str])
/// 	}
/// 
/// 	convenience init(_ str: String, scheme: String) throws {
/// 		try self.init(method: "new", args: [str, scheme])
/// 	}
/// 
/// 	convenience init(copyOf uri: URI) {
/// 		try! self.init(uri.call(method: "clone") as PerlScalar)
/// 	}
/// 
/// 	var scheme: String? { return try! call(method: "scheme") }
/// 	func scheme(_ scheme: String) throws -> String? { return try call(method: "scheme", scheme) }
/// 
/// 	var path: String {
/// 		get { return try! call(method: "path") }
/// 		set { try! call(method: "path", newValue) as Void }
/// 	}
/// 
/// 	var asString: String { return try! call(method: "as_string") }
/// 
/// 	func abs(base: String) -> String { return try! call(method: "abs", base) }
/// 	func rel(base: String) -> String { return try! call(method: "rel", base) }
/// 
/// 	var secure: Bool { return try! call(method: "secure") }
/// }
/// ```
open class PerlObject : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeSV

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

	/// Creates a new object by calling its Perl constructor.
	///
	/// Use this `init` only to construct instances of
	/// subclasses conforming to `PerlNamedClass`.
	///
	/// The recomended way is to wrap this constructor
	/// invocations by implementing more concrete initializers
	/// which hide Perl method calling magic behind.
	///
	/// Let's imagine a class:
	///
	/// ```swift
	/// final class URI : PerlObject, PerlNamedClass {
	/// 	static let perlClassName = "URI"
	///
	/// 	convenience init(_ str: String) throws {
	/// 		try self.init(method: "new", args: [str])
	/// 	}
	/// }
	/// ```
	///
	/// Then Swift expression:
	///
	/// ```swift
	/// let uri = URI("https://my.mail.ru/music")
	/// ```
	///
	/// will be equal to Perl:
	///
	/// ```perl
	/// my $uri = URI->new("https://my.mail.ru/music")
	/// ```
	///
	/// - Parameter method: A name of the constuctor. Usually it is *new*.
	/// - Parameter args: Arguments to pass to the constructor.
	/// - Parameter perl: The Perl interpreter.
	public convenience init(method: String, args: [PerlSvConvertible?], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		guard let named = type(of: self) as? PerlNamedClass.Type else {
			fatalError("PerlObject.init(method:args:perl) is only supported for subclasses conforming to PerlNamedClass")
		}
		perl.pointee.enterScope()
		defer { perl.pointee.leaveScope() }
		let classname = named.perlClassName
		let args = [classname as PerlSvConvertible?] + args
		let svArgs: [UnsafeSvPointer] = args.map { $0?._toUnsafeSvPointer(perl: perl) ?? perl.pointee.newSV() }
		let sv = try perl.pointee.unsafeCall(sv: perl.pointee.newSV(method, mortal: true), args: svArgs, flags: G_METHOD|G_SCALAR)[0]
		guard sv.pointee.isObject(perl: perl) else {
			throw PerlError.notObject(fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		guard sv.pointee.isDerived(from: classname, perl: perl) else {
			throw PerlError.unexpectedObjectType(fromUnsafeSvPointer(inc: sv, perl: perl), want: type(of: self))
		}
		self.init(incUnchecked: sv, perl: perl)
	}

	public convenience init(_ sv: PerlScalar) throws {
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

	/// A textual representation of the SV, suitable for debugging.
	public override var debugDescription: String {
		var rvDesc = ""
		debugPrint(referent, terminator: "", to: &rvDesc)
		return "\(type(of: self))(\(perlClassName), rv=\(rvDesc))"
	}

	static func derivedClass(for classname: String) -> PerlObject.Type {
		return classMapping[classname] ?? PerlObject.self
	}

	static var classMapping = [String: PerlObject.Type ]()

	/// Registers class `swiftClass` as a counterpart of Perl's class with name `classname`.
	public static func register<T>(_ swiftClass: T.Type, as classname: String) where T : PerlObject, T : PerlNamedClass {
		classMapping[classname] = swiftClass
	}
}

/// A Swift class which instances can be passed to Perl as a blessed SV.
///
/// Implementing an object that conforms to `PerlBridgedObject` is simple.
/// Declare a `static var perlClassName` that contains a name of the Perl class
/// your Swift class should be bridged to. Use `addPerlMethod` method on
/// startup to provide ability to access your methods and attributes from Perl.
public protocol PerlBridgedObject : AnyPerl, PerlNamedClass, PerlSvConvertible {}

/// A class having Perl representation.
public protocol PerlNamedClass : class {
	/// A name of the class in Perl.
	static var perlClassName: String { get }
}

extension PerlNamedClass {
	/// Loads the module which name is in `perlClassName` attribute.
	public static func require(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		try perl.pointee.require(perlClassName)
	}

	/// Loads the module which name is in `perlClassName` attribute.
	@available(*, deprecated, renamed: "require(perl:)")
	public static func loadModule(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		perl.pointee.loadModule(perlClassName)
	}
}

extension PerlNamedClass where Self : PerlObject {
	/// Registers this class as a counterpart of Perl class which name is provided in `perlClassName`.
	public static func register() {
		PerlObject.register(self, as: (self as PerlNamedClass.Type).perlClassName)
	}

	/// Assuming that the Perl class is in the module with the same name, loads it and registers.
	public static func initialize(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		try require(perl: perl)
		register()
	}

	@available(*, deprecated, renamed: "initialize(perl:)")
	public static func loadAndRegister(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		loadModule(perl: perl)
		register()
	}
}
