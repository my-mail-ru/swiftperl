protocol UnsafeSvProtocol {}
protocol UnsafeSvCastProtocol : UnsafeSvProtocol {}
extension UnsafeSV : UnsafeSvProtocol {}
extension UnsafeAV : UnsafeSvCastProtocol {}
extension UnsafeHV : UnsafeSvCastProtocol {}
extension UnsafeCV : UnsafeSvCastProtocol {}

extension UnsafeSvCastProtocol {
	typealias Pointer = UnsafeMutablePointer<Self>

	@discardableResult
	mutating func refcntInc() -> UnsafeMutablePointer<Self> {
		return Pointer(UnsafeSvPointer(forceUnsafeMutablePointer(&self)).pointee.refcntInc())
	}

	mutating func refcntDec(perl: UnsafeInterpreterPointer) {
		UnsafeSvPointer(forceUnsafeMutablePointer(&self)).pointee.refcntDec(perl: perl)
	}
}

func forceUnsafeMutablePointer<T>(_ p: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> { return p }
