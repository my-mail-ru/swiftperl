public protocol PerlSvConvertible {
	init(_fromUnsafeSvContextInc: UnsafeSvContext) throws
	init(_fromUnsafeSvContextCopy: UnsafeSvContext) throws
	func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer
}

extension PerlSvConvertible {
	public init(_fromUnsafeSvContextCopy svc: UnsafeSvContext) throws {
		try self.init(_fromUnsafeSvContextInc: svc)
	}
}

extension Bool : PerlSvConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) { self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.newSV(self) }
}

extension Int : PerlSvConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.pointee.newSViv(self) }
}

extension UInt : PerlSvConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.pointee.newSVuv(self) }
}

extension Double : PerlSvConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.pointee.newSVnv(self) }
}

extension String : PerlSvConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.newSV(self) }
}

extension PerlScalar : PerlSvConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: svc)
	}

	public convenience init(_fromUnsafeSvContextCopy svc: UnsafeSvContext) throws {
		try self.init(copy: svc)
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		defer { _fixLifetime(self) }
		return unsafeSvContext.refcntInc()
	}
}

extension PerlArray : PerlSvConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: UnsafeAvContext(dereference: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return withUnsafeSvContext { $0.perl.pointee.newRV_inc($0.sv) }
	}
}

extension PerlHash : PerlSvConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: UnsafeHvContext(dereference: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return withUnsafeSvContext { $0.perl.pointee.newRV_inc($0.sv) }
	}
}

extension PerlSub : PerlSvConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: UnsafeCvContext(dereference: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return withUnsafeSvContext { $0.perl.pointee.newRV_inc($0.sv) }
	}
}

extension PerlSvConvertible where Self : PerlBridgedObject {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		guard let object = svc.swiftObject else {
			throw PerlError.notSwiftObject(Perl.fromUnsafeSvContext(inc: svc))
		}
		guard let derivedObject = object as? Self else {
			throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvContext(inc: svc), want: Self.self)
		}
		self = derivedObject
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return perl.newSV(self)
	}
}

extension PerlSvConvertible where Self : PerlObject {
	private init(fromUnsafeSvContextNoinc svc: UnsafeSvContext) throws {
		guard let classname = svc.classname else {
			throw PerlError.notObject(Perl.fromUnsafeSvContext(noinc: svc))
		}
		if let nc = Self.self as? PerlNamedClass.Type, nc.perlClassName == classname {
			self.init(noincUnchecked: svc)
		} else {
			let derivedClass = PerlObject.derivedClass(for: classname)
			if derivedClass == Self.self {
				self.init(noincUnchecked: svc)
			} else {
				guard let dc = derivedClass as? Self.Type else {
					throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvContext(noinc: svc), want: Self.self)
				}
				self.init(as: dc, noinc: svc)
			}
		}
	}

	private init(as derivedClass: Self.Type, noinc svc: UnsafeSvContext) {
		self = derivedClass.init(noincUnchecked: svc)
	}

	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		svc.refcntInc()
		try self.init(fromUnsafeSvContextNoinc: svc)
	}

	public init(_fromUnsafeSvContextCopy svc: UnsafeSvContext) throws {
		try self.init(fromUnsafeSvContextNoinc: UnsafeSvContext.new(stealingCopy: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		defer { _fixLifetime(self) }
		return unsafeSvContext.refcntInc()
	}
}

extension Optional where Wrapped : PerlSvConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		self = svc.defined ? .some(try Wrapped(_fromUnsafeSvContextInc: svc)) : .none
	}

	public init(_fromUnsafeSvContextCopy svc: UnsafeSvContext) throws {
		self = svc.defined ? .some(try Wrapped(_fromUnsafeSvContextCopy: svc)) : .none
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		switch self {
			case .some(let value):
				return value._toUnsafeSvPointer(perl: perl)
			case .none:
				return perl.pointee.newSV(0)
		}
	}
}

extension Array where Element : PerlSvConvertible {
	func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		let avc = UnsafeAvContext.new(perl: perl)
		avc.reserveCapacity(numericCast(count))
		for (i, v) in enumerated() {
			avc.store(i, value: v._toUnsafeSvPointer(perl: perl))
		}
		return UnsafeSvContext.new(rvNoinc: avc).sv
	}
}

extension Dictionary where Value : PerlSvConvertible {
	func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		let hvc = UnsafeHvContext.new(perl: perl)
		for (k, v) in self {
			hvc.store("\(k)", value: v._toUnsafeSvPointer(perl: perl))
		}
		return UnsafeSvContext.new(rvNoinc: hvc).sv
	}
}
