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
open class PerlObject : PerlValue, PerlSvConvertible {
	convenience init(noinc svc: UnsafeSvContext) throws {
		guard svc.isObject else {
			throw PerlError.notObject(fromUnsafeSvContext(noinc: svc))
		}
		if let named = type(of: self) as? PerlNamedClass.Type {
			guard svc.isDerived(from: named.perlClassName) else {
				throw PerlError.unexpectedObjectType(fromUnsafeSvContext(noinc: svc), want: type(of: self))
			}
		}
		self.init(noincUnchecked: svc)
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
	public convenience init(method: String, args: [PerlSvConvertible?], perl: PerlInterpreter = .current) throws {
		guard let named = type(of: self) as? PerlNamedClass.Type else {
			fatalError("PerlObject.init(method:args:perl) is only supported for subclasses conforming to PerlNamedClass")
		}
		perl.enterScope()
		defer { perl.leaveScope() }
		let classname = named.perlClassName
		let args = [classname as PerlSvConvertible?] + args
		let svArgs: [UnsafeSvPointer] = args.map { $0?._toUnsafeSvPointer(perl: perl) ?? perl.pointee.newSV(0) }
		let sv = try perl.unsafeCall(sv: perl.newSV(method, mortal: true), args: svArgs, flags: G_METHOD|G_SCALAR)[0]
		let svc = UnsafeSvContext(sv: sv, perl: perl)
		guard svc.isObject else {
			throw PerlError.notObject(fromUnsafeSvContext(inc: svc))
		}
		guard svc.isDerived(from: classname) else {
			throw PerlError.unexpectedObjectType(fromUnsafeSvContext(inc: svc), want: type(of: self))
		}
		self.init(incUnchecked: svc)
	}

	public convenience init(_ scalar: PerlScalar) throws {
		defer { _fixLifetime(scalar) }
		try self.init(inc: scalar.unsafeSvContext)
	}

	/// Returns the specified Perl global or package object with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then `nil` is returned.
	public convenience init?(get name: String, perl: PerlInterpreter = .current) throws {
		guard let sv = perl.getSV(name) else { return nil }
		try self.init(inc: UnsafeSvContext(sv: sv, perl: perl))
	}

	var perlClassName: String {
		defer { _fixLifetime(self) }
		return unsafeSvContext.classname!
	}

	var referent: AnyPerl {
		defer { _fixLifetime(self) }
		return fromUnsafeSvContext(inc: unsafeSvContext.referent!)
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

	// Workaround for https://bugs.swift.org/browse/SR-5056
	public required init(noincUnchecked svc: UnsafeSvContext) {
		super.init(noincUnchecked: svc)
	}

	// Workaround for https://bugs.swift.org/browse/SR-5056
	public required init(incUnchecked svc: UnsafeSvContext) {
		super.init(incUnchecked: svc)
	}

	private convenience init(_fromUnsafeSvContextNoinc svc: UnsafeSvContext) throws {
		guard let classname = svc.classname else {
			throw PerlError.notObject(Perl.fromUnsafeSvContext(noinc: svc))
		}
		if let nc = type(of: self) as? PerlNamedClass.Type, nc.perlClassName == classname {
			self.init(noincUnchecked: svc)
		} else {
			let derivedClass = PerlObject.derivedClass(for: classname)
			if derivedClass == type(of: self) {
				self.init(noincUnchecked: svc)
			} else {
				guard isStrictSubclass(derivedClass, of: type(of: self)) else {
					throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvContext(noinc: svc), want: type(of: self))
				}
				self.init(as: derivedClass, noinc: svc)
			}
		}
	}

	public required convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		svc.refcntInc()
		try self.init(_fromUnsafeSvContextNoinc: svc)
	}

	public required convenience init(_fromUnsafeSvContextCopy svc: UnsafeSvContext) throws {
		try self.init(_fromUnsafeSvContextNoinc: UnsafeSvContext.new(stealingCopy: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		defer { _fixLifetime(self) }
		return unsafeSvContext.refcntInc()
	}
}

// Dirty hack to initialize instance of another class (subclass).
extension PerlSvConvertible where Self : PerlObject {
	init(as derivedClass: Self.Type, noinc svc: UnsafeSvContext) {
		self = derivedClass.init(noincUnchecked: svc)
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
	public static func require(perl: PerlInterpreter = .current) throws {
		try perl.require(perlClassName)
	}
}

extension PerlNamedClass where Self : PerlObject {
	/// Registers this class as a counterpart of Perl class which name is provided in `perlClassName`.
	public static func register() {
		PerlObject.register(self, as: (self as PerlNamedClass.Type).perlClassName)
	}

	/// Assuming that the Perl class is in the module with the same name, loads it and registers.
	public static func initialize(perl: PerlInterpreter = .current) throws {
		try require(perl: perl)
		register()
	}
}
