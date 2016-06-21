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
		return S_SvREFCNT_inc_NN(&self)
	}

	mutating func refcntDec(perl: UnsafeInterpreterPointer) {
		S_SvREFCNT_dec_NN(perl, &self)
	}

	var type: SvType { mutating get { return SvType(SvTYPE(&self)) } }
	var defined: Bool { mutating get { return SvOK(&self) } }
	var isInt: Bool { mutating get { return SvIOK(&self) } }
	var isString: Bool { mutating get { return SvPOK(&self) } }
	var isRef: Bool { mutating get { return SvROK(&self) } }
	mutating func isObject(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool { return Perl_sv_isobject(perl, &self) != 0 }

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
				return UnsafeAvPointer(forceUnsafeMutablePointer(&self))
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
				return UnsafeHvPointer(forceUnsafeMutablePointer(&self))
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
				return UnsafeCvPointer(forceUnsafeMutablePointer(&self))
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
		let sv = SvRV(&self)
		guard SvTYPE(sv) == SVt_PVMG && Perl_mg_findext(perl, sv, PERL_MAGIC_ext, &objectMgvtbl) != nil else {
			throw PerlError.notSwiftObject(self.value())
		}
		let iv = perl.pointee.SvIV(sv)
		let u = Unmanaged<AnyObject>.fromOpaque(OpaquePointer(bitPattern: iv)!)
		let any = u.takeUnretainedValue()
		guard let obj = any as? T else { throw PerlError.unexpectedSwiftObject(self.value()) }
		return obj
	}

	mutating func value<T: PerlObjectType>(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard isObject(perl: perl) else { throw PerlError.notObject(self.value()) }
		let classname = String(cString: Perl_sv_reftype(perl, SvRV(&self), 1))
		guard let perlClass = PerlInterpreter.classMapping[classname] else { throw PerlError.unsupportedPerlClass(self.value()) }
		guard let obj = perlClass.init(PerlSV(&self)) as? T else { throw PerlError.unexpectedPerlClass(self.value()) } // FIXME remove PerlSV cast
		return obj
	}
}

extension UnsafeInterpreter {
	mutating func newSV() -> UnsafeSvPointer {
		return Perl_newSV(&self, 0)
	}

	mutating func newSV(_ v: UnsafeSvPointer) -> UnsafeSvPointer {
		return Perl_newSVsv(&self, v)
	}

	mutating func newSV(_ v: Bool) -> UnsafeSvPointer {
		return v ? Perl_newSVsv(&self, &Isv_yes) : Perl_newSVsv(&self, &Isv_no)
	}

	mutating func newSV(_ v: Int) -> UnsafeSvPointer {
		return Perl_newSViv(&self, v)
	}

	mutating func newSV(_ v: String, mortal: Bool = false) -> UnsafeSvPointer {
		let flags = mortal ? SVf_UTF8|SVs_TEMP : SVf_UTF8
		return v.withCStringWithLength { Perl_newSVpvn_flags(&self, $0, $1, UInt32(flags)) }
	}

	mutating func newRV<T: UnsafeSvProtocol>(inc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return Perl_newRV(&self, UnsafeSvPointer(v))
	}

	mutating func newRV<T: UnsafeSvProtocol>(noinc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return Perl_newRV_noinc(&self, UnsafeSvPointer(v))
	}

	mutating func newSV(_ v: PerlMappedClass) -> UnsafeSvPointer {
		let u = Unmanaged<AnyObject>.passRetained(v)
		let iv = unsafeBitCast(u, to: Int.self)
		let sv = v.dynamicType.perlClassName.withCString {
			Perl_sv_setref_iv(&self, Perl_newSV(&self, 0), $0, iv)!
		}
		Perl_sv_magicext(&self, SvRV(sv), nil, PERL_MAGIC_ext, &objectMgvtbl, nil, 0)
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
		let iv = perl!.pointee.SvIV(sv)
		let u = Unmanaged<AnyObject>.fromOpaque(OpaquePointer(bitPattern: iv)!)
		u.release()
		return 0
	},
	svt_copy: nil,
	svt_dup: nil,
	svt_local: nil
)
