# Swift and Perl Interoperability

![Swift: 4.0](https://img.shields.io/badge/Swift-4.0-orange.svg)
![OS: Linux | macOS](https://img.shields.io/badge/OS-Linux%20%7C%20macOS-brightgreen.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

*swiftperl* is designed to provide an easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift,
though running Perl Interpreter in Swift environment is also possible.

## Prerequisites

* Swift 4.0
* Perl 5 (>=5.10)

## Getting Started

### Linux

```sh
swift test -Xcc -D_GNU_SOURCE
```

### macOS

```sh
PKG_CONFIG_PATH=$PWD/.build/pkgconfig swift test --disable-sandbox
```

## Documentation

For information on using *swiftperl*, see [Reference](https://my-mail-ru.github.io/swiftperl/).

## Stability

The API stability is guaranteed in accordance with [Semantic Versioning](http://semver.org/).

The module is used in [production](https://my.mail.ru/) helping to serve thousands
requests per second.
