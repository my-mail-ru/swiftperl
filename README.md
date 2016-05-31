# Swift and Perl Interoperability

swiftperl is designed to provide easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift,
though running Perl Interpreter in Swift environment will also be possible.

This package is on very early stage of development.
It wasn't tested at all and runs without modification only on Ubunty 15.10.

## Prerequisites

* Swift 3.0 DEVELOPMENT-SNAPSHOT-2016-05-09-a [Ubuntu 15.10](https://swift.org/builds/development/ubuntu1510/swift-DEVELOPMENT-SNAPSHOT-2016-05-09-a/swift-DEVELOPMENT-SNAPSHOT-2016-05-09-a-ubuntu15.10.tar.gz)
* Perl 5

## Getting Started

	rm -rf .git # repository at this point of development contains no tags, so we have to build without git
	swift build
