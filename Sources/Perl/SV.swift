protocol PerlSVProtocol {
	associatedtype Struct

	var pointer: UnsafeMutablePointer<Struct> { get }
	var perl: UnsafeInterpreterPointer { get }

	init(_: UnsafeMutablePointer<Struct>, perl: UnsafeInterpreterPointer)
}

protocol PerlSvCastable : PerlSVProtocol, PerlSVProbablyConvertible {
	associatedtype Struct : UnsafeSvCastable
	init?(_ sv: PerlSV) throws
}

final class PerlSV : PerlSVProtocol {
	typealias Struct = UnsafeSV
	typealias Pointer = UnsafeSvPointer
	let pointer: Pointer
	let perl: UnsafeInterpreterPointer

	init(_ p: Pointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = p.pointee.refcntInc()
	}

	convenience init() { self.init(perl: UnsafeInterpreter.current) } // default bellow doesn't work...

	init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = perl.pointee.newSV()
	}

	init<T : PerlSVConvertible>(_ v: T, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = v.promoteToUnsafeSV(perl: perl)
	}

	init<T: PerlSVProtocol>(referenceTo sv: T) {
		perl = sv.perl
		pointer = sv.pointer.withMemoryRebound(to: UnsafeSV.self, capacity: 1) {
			sv.perl.pointee.newRV(inc: $0)
		}
	}

	init<T : PerlSVConvertible>(_ array: [T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = array.promoteToUnsafeSV(perl: perl)
	}

	init<T : PerlSVConvertible>(_ dict: [String: T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = dict.promoteToUnsafeSV(perl: perl)
	}

	convenience init<T : PerlSVConvertible>(_ v: T?, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		if let v = v {
			self.init(v, perl: perl)
		} else {
			self.init(perl: perl)
		}
	}

	deinit {
		pointer.pointee.refcntDec(perl: perl)
	}

	var type: SvType { return pointer.pointee.type }
	var defined: Bool { return pointer.pointee.defined }
	var isInt: Bool { return pointer.pointee.isInt }
	var isString: Bool { return pointer.pointee.isString }
	var isRef: Bool { return pointer.pointee.isRef }
	var isObject: Bool { return pointer.pointee.isObject(perl: perl) }

	var referent: PerlSV? {
		guard let sv = pointer.pointee.referent else { return nil }
		return PerlSV(sv)
	}
}

extension PerlSV : ExpressibleByNilLiteral {
	convenience init(nilLiteral: ()) {
		self.init()
	}
}

extension PerlSV: ExpressibleByBooleanLiteral {
	convenience init(booleanLiteral value: Bool) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByIntegerLiteral {
	convenience init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByUnicodeScalarLiteral {
	convenience init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByExtendedGraphemeClusterLiteral {
	convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByStringLiteral {
	convenience init(stringLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV: ExpressibleByArrayLiteral {
	convenience init (arrayLiteral elements: PerlSV...) {
		self.init(PerlAV(elements))
	}
}

extension PerlSV : ExpressibleByDictionaryLiteral {
	convenience init(dictionaryLiteral elements: (String, PerlSV)...) {
		self.init(PerlHV(elements))
	}
}

extension Bool {
	init(_ sv: PerlSV) {
		self.init(sv.pointer, perl: sv.perl)
	}
}

extension Int {
	init?(_ sv: PerlSV) {
		self.init(sv.pointer, perl: sv.perl)
	}

	init(forcing sv: PerlSV) {
		self.init(forcing: sv.pointer, perl: sv.perl)
	}
}

extension String {
	init?(_ sv: PerlSV) {
		self.init(sv.pointer, perl: sv.perl)
	}

	init(forcing sv: PerlSV) {
		self.init(forcing: sv.pointer, perl: sv.perl)
	}
}
