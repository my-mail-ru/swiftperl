public protocol PerlScalarConvertible {
	init(_fromUnsafeSvContextInc: UnsafeSvContext) throws
	init(_fromUnsafeSvContextCopy: UnsafeSvContext) throws
	func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer
}

extension PerlScalarConvertible {
	public init(_fromUnsafeSvContextCopy svc: UnsafeSvContext) throws {
		try self.init(_fromUnsafeSvContextInc: svc)
	}
}

extension Bool : PerlScalarConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) { self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.newSV(self) }
}

extension Int : PerlScalarConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.pointee.newSViv(self) }
}

extension UInt : PerlScalarConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.pointee.newSVuv(self) }
}

extension Double : PerlScalarConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.pointee.newSVnv(self) }
}

extension String : PerlScalarConvertible {
	public init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws { try self.init(svc) }
	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer { return perl.newSV(self) }
}

extension PerlScalar : PerlScalarConvertible {
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

extension PerlArray : PerlScalarConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: UnsafeAvContext(dereference: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return withUnsafeSvContext { $0.perl.pointee.newRV_inc($0.sv) }
	}
}

extension PerlHash : PerlScalarConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: UnsafeHvContext(dereference: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return withUnsafeSvContext { $0.perl.pointee.newRV_inc($0.sv) }
	}
}

extension PerlSub : PerlScalarConvertible {
	public convenience init(_fromUnsafeSvContextInc svc: UnsafeSvContext) throws {
		try self.init(inc: UnsafeCvContext(dereference: svc))
	}

	public func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		return withUnsafeSvContext { $0.perl.pointee.newRV_inc($0.sv) }
	}
}

extension PerlScalarConvertible where Self : PerlBridgedObject {
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

extension Optional where Wrapped : PerlScalarConvertible {
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

extension Array where Element : PerlScalarConvertible {
	func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		let avc = UnsafeAvContext.new(perl: perl)
		avc.reserveCapacity(numericCast(count))
		for (i, v) in enumerated() {
			avc.store(i, value: v._toUnsafeSvPointer(perl: perl))
		}
		return UnsafeSvContext.new(rvNoinc: avc).sv
	}
}

extension Dictionary where Value : PerlScalarConvertible {
	func _toUnsafeSvPointer(perl: PerlInterpreter) -> UnsafeSvPointer {
		let hvc = UnsafeHvContext.new(perl: perl)
		for (k, v) in self {
			hvc.store("\(k)", value: v._toUnsafeSvPointer(perl: perl))
		}
		return UnsafeSvContext.new(rvNoinc: hvc).sv
	}
}
