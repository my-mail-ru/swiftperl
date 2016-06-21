# Swift and Perl Interoperability

swiftperl is designed to provide easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift,
though running Perl Interpreter in Swift environment is also possible.

This package is on very early stage of development.
It was never used in production and runs without modification on Ubunty 15.10 only.

## Prerequisites

* Swift 3.0 preview 1 [Ubuntu 15.10](https://swift.org/builds/swift-3.0-preview-1/ubuntu1510/swift-3.0-preview-1/swift-3.0-preview-1-ubuntu15.10.tar.gz)
* Perl 5

## Getting Started

	./gybme
	swift build
	swift test
