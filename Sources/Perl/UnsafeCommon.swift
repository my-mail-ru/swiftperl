public protocol UnsafeSvProtocol {
	static var type: SvType { get }
}

extension UnsafeSV : UnsafeSvProtocol {
	public static var type: SvType { return .scalar }
}

public protocol UnsafeSvCastable : UnsafeSvProtocol {}

extension UnsafeAV : UnsafeSvCastable {
	public static var type: SvType { return .array }
}

extension UnsafeHV : UnsafeSvCastable {
	public static var type: SvType { return .hash }
}

extension UnsafeCV : UnsafeSvCastable {
	public static var type: SvType { return .code }
}
