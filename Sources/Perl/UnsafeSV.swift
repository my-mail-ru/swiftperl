import CPerl

enum SvType {
	case scalar, array, hash, code, format, io

	init(_ t: svtype) {
		switch t {
			case SVt_PVAV:
				self = .array
			case SVt_PVHV:
				self = .hash
			case SVt_PVCV:
				self = .code
			case SVt_PVFM:
				self = .format
			case SVt_PVIO:
				self = .io
			default:
				self = .scalar
		}
	}
}

typealias UnsafeSV = CPerl.SV
typealias UnsafeSvPointer = UnsafeMutablePointer<UnsafeSV>

extension UnsafeSV {
	@discardableResult
	mutating func refcntInc() -> UnsafeSvPointer {
		return SvREFCNT_inc(&self)
	}

	mutating func refcntDec(perl: UnsafeInterpreterPointer) {
		SvREFCNT_dec(perl, &self)
	}

	var type: SvType { mutating get { return SvType(SvTYPE(&self)) } }
	var defined: Bool { mutating get { return SvOK(&self) } }
	var isInt: Bool { mutating get { return SvIOK(&self) } }
	var isString: Bool { mutating get { return SvPOK(&self) } }
	var isRef: Bool { mutating get { return SvROK(&self) } }

	mutating func isObject(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool {
		return perl.pointee.sv_isobject(&self)
	}

	var refValue: UnsafeSvPointer? { mutating get { return SvROK(&self) ? SvRV(&self) : nil } }

	mutating func value(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool {
		return perl.pointee.SvTRUE(&self)
	}

	mutating func value(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Int {
		return perl.pointee.SvIV(&self)
	}

	mutating func value(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> String {
		var clen = 0
		let cstr = perl.pointee.SvPV(&self, &clen)!
		return String(cString: cstr, withLength: clen)
	}

	mutating func value() throws -> UnsafeAvPointer {
		switch type {
			case .array:
				return UnsafeMutableRawPointer(&self).bindMemory(to: UnsafeAV.self, capacity: 1)
			case .scalar:
				if let v = refValue {
					return try v.pointee.value()
				} else {
					fallthrough
				}
			default:
				throw PerlError.notAV(self.value())
		}
	}

	mutating func value() throws -> UnsafeHvPointer {
		switch type {
			case .hash:
				return UnsafeMutableRawPointer(&self).bindMemory(to: UnsafeHV.self, capacity: 1)
			case .scalar:
				if let v = refValue {
					return try v.pointee.value()
				} else {
					fallthrough
				}
			default:
				throw PerlError.notHV(self.value())
		}
	}

	mutating func value() throws -> UnsafeCvPointer {
		switch type {
			case .code:
				return UnsafeMutableRawPointer(&self).bindMemory(to: UnsafeCV.self, capacity: 1)
			case .scalar:
				if let v = refValue {
					return try v.pointee.value()
				} else {
					fallthrough
				}
			default:
				throw PerlError.notCV(self.value())
		}
	}

	mutating func value() -> PerlSV {
		return PerlSV(&self)
	}

	mutating func value() throws -> PerlAV {
		return PerlAV(try self.value() as UnsafeAvPointer)
	}

	mutating func value() throws -> PerlHV {
		return PerlHV(try self.value() as UnsafeHvPointer)
	}

	mutating func value() throws -> PerlCV {
		return PerlCV(try self.value() as UnsafeCvPointer)
	}

	mutating func value<T: PerlMappedClass>(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard isObject(perl: perl) else { throw PerlError.notObject(self.value()) }
		let sv = SvRV(&self)!
		guard SvTYPE(sv) == SVt_PVMG && perl.pointee.mg_findext(sv, PERL_MAGIC_ext, &objectMgvtbl) != nil else {
			throw PerlError.notSwiftObject(self.value())
		}
		let iv = perl.pointee.SvIV(sv)
		let u = Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(bitPattern: iv)!)
		let any = u.takeUnretainedValue()
		guard let obj = any as? T else { throw PerlError.unexpectedSwiftObject(self.value()) }
		return obj
	}

	mutating func value<T: PerlObjectType>(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard isObject(perl: perl) else { throw PerlError.notObject(self.value()) }
		let classname = String(cString: perl.pointee.sv_reftype(SvRV(&self), 1))
		guard let perlClass = PerlInterpreter.classMapping[classname] else { throw PerlError.unsupportedPerlClass(self.value()) }
		guard let obj = perlClass.init(PerlSV(&self)) as? T else { throw PerlError.unexpectedPerlClass(self.value()) } // FIXME remove PerlSV cast
		return obj
	}
}

extension UnsafeInterpreter {
	mutating func newSV(_ v: Bool) -> UnsafeSvPointer {
		return newSV(boolSV(v))
	}

	mutating func newSV(_ v: String, mortal: Bool = false) -> UnsafeSvPointer {
		let flags = mortal ? SVf_UTF8|SVs_TEMP : SVf_UTF8
		return v.withCStringWithLength { newSVpvn_flags($0, $1, UInt32(flags)) }
	}

	mutating func newRV<T: UnsafeSvCastProtocol>(inc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return v.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { newRV(inc: $0) }
	}

	mutating func newRV<T: UnsafeSvCastProtocol>(noinc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return v.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { newRV(noinc: $0) }
	}

	mutating func newSV(_ v: PerlMappedClass) -> UnsafeSvPointer {
		let u = Unmanaged<AnyObject>.passRetained(v)
		let iv = unsafeBitCast(u, to: Int.self)
		let sv = sv_setref_iv(newSV(), type(of: v).perlClassName, iv)
		sv_magicext(SvRV(sv), nil, PERL_MAGIC_ext, &objectMgvtbl, nil, 0)
		return sv
	}
}

private var objectMgvtbl = MGVTBL(
	svt_get: nil,
	svt_set: nil,
	svt_len: nil,
	svt_clear: nil,
	svt_free: {
		(perl, sv, magic) in
		let iv = perl.unsafelyUnwrapped.pointee.SvIV(sv.unsafelyUnwrapped)
		let u = Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(bitPattern: iv)!)
		u.release()
		return 0
	},
	svt_copy: nil,
	svt_dup: nil,
	svt_local: nil
)
