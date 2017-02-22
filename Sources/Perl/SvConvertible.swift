public protocol PerlSvConvertible {
	init(_fromUnsafeSvPointerInc: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws
	init(_fromUnsafeSvPointerCopy: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws
	func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer
}

extension PerlSvConvertible {
	public init(_fromUnsafeSvPointerCopy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_fromUnsafeSvPointerInc: sv, perl: perl)
	}
}

extension Bool : PerlSvConvertible {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) { self.init(sv, perl: perl) }
	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension Int : PerlSvConvertible {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws { try self.init(sv, perl: perl) }
	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension Double : PerlSvConvertible {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws { try self.init(sv, perl: perl) }
	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension String : PerlSvConvertible {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws { try self.init(sv, perl: perl) }
	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension PerlScalar : PerlSvConvertible {
	public convenience init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(inc: sv, perl: perl)
	}

	public convenience init(_fromUnsafeSvPointerCopy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(copy: sv, perl: perl)
	}

	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}
}

extension PerlDerived where Self : PerlValue, UnsafeValue : UnsafeSvCastable {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		guard let unsafe = try UnsafeMutablePointer<UnsafeValue>(autoDeref: sv, perl: perl) else {
			throw PerlError.unexpectedUndef(Perl.fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		self.init(inc: unsafe, perl: perl)
	}

	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, perl in perl.pointee.newRV(inc: sv) }
	}
}

extension PerlSvConvertible where Self : PerlBridgedObject {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		guard let object = sv.pointee.swiftObject(perl: perl) else {
			throw PerlError.notSwiftObject(Perl.fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		guard let derivedObject = object as? Self else {
			throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvPointer(inc: sv, perl: perl), want: Self.self)
		}
		self = derivedObject
	}

	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		return perl.pointee.newSV(self)
	}

	@available(*, deprecated, message: "This ugly hack is not needed anymore")
	public static func _fromUnsafeSvPointerNonFinalClassWorkaround<T>(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws -> T {
		fatalError("shouldn't be here")
	}
}

extension PerlSvConvertible where Self : PerlObject {
	private init(fromUnsafeSvPointerNoinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		guard let classname = sv.pointee.classname(perl: perl) else {
			throw PerlError.notObject(Perl.fromUnsafeSvPointer(noinc: sv, perl: perl))
		}
		if let nc = Self.self as? PerlNamedClass.Type, nc.perlClassName == classname {
			self.init(noincUnchecked: sv, perl: perl)
		} else {
			let derivedClass = PerlObject.derivedClass(for: classname)
			if derivedClass == Self.self {
				self.init(noincUnchecked: sv, perl: perl)
			} else {
				guard let dc = derivedClass as? Self.Type else {
					throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvPointer(noinc: sv, perl: perl), want: Self.self)
				}
				self.init(as: dc, noinc: sv, perl: perl)
			}
		}
	}

	private init(as derivedClass: Self.Type, noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) {
		self = derivedClass.init(noincUnchecked: sv, perl: perl)
	}

	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(fromUnsafeSvPointerNoinc: sv.pointee.refcntInc(), perl: perl)
	}

	public init(_fromUnsafeSvPointerCopy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(fromUnsafeSvPointerNoinc: perl.pointee.newSV(stealing: sv), perl: perl)
	}

	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}
}

extension Optional where Wrapped : PerlSvConvertible {
	public init(_fromUnsafeSvPointerInc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		self = sv.pointee.defined ? .some(try Wrapped(_fromUnsafeSvPointerInc: sv, perl: perl)) : .none
	}

	public init(_fromUnsafeSvPointerCopy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		self = sv.pointee.defined ? .some(try Wrapped(_fromUnsafeSvPointerCopy: sv, perl: perl)) : .none
	}

	public func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		switch self {
			case .some(let value):
				return value._toUnsafeSvPointer(perl: perl)
			case .none:
				return perl.pointee.newSV()
		}
	}
}

extension Array where Element : PerlSvConvertible {
	func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		let av = perl.pointee.newAV()!
		var c = av.pointee.collection(perl: perl)
		c.reserveCapacity(numericCast(count))
		for (i, v) in enumerated() {
			c[i] = v._toUnsafeSvPointer(perl: perl)
		}
		return perl.pointee.newRV(noinc: av)
	}
}

// where Key == String, but it is unsupported
extension Dictionary where Value : PerlSvConvertible {
	func _toUnsafeSvPointer(perl: UnsafeInterpreterPointer) -> UnsafeSvPointer {
		let hv = perl.pointee.newHV()!
		var c = hv.pointee.collection(perl: perl)
		for (k, v) in self {
			c[k as! String] = v._toUnsafeSvPointer(perl: perl)
		}
		return perl.pointee.newRV(noinc: hv)
	}
}
