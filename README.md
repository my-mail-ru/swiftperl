# Swift and Perl Interoperability

![Swift: 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg)
![OS: Linux](https://img.shields.io/badge/OS-Linux-brightgreen.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

*swiftperl* is designed to provide an easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift,
though running Perl Interpreter in Swift environment is also possible.

## Prerequisites

* Swift 3.0 Release
* Perl 5 (>=5.10)

## Getting Started

Ubuntu 15.10:

```sh
./gybme
swift test -Xcc -isystem/usr/lib/x86_64-linux-gnu/perl/5.20/CORE -Xcc -D_GNU_SOURCE -Xcc -DPERL_NO_GET_CONTEXT
```

CentOS 6:

```sh
./gybme
LD_LIBRARY_PATH=/usr/lib64/perl5/CORE/ swift test -Xcc -isystem/usr/lib64/perl5/CORE/ -Xcc -D_GNU_SOURCE -Xcc -DPERL_NO_GET_CONTEXT -Xlinker -L/usr/lib64/perl5/CORE/
```

## Documentation

For information on using *swiftperl*, see [Reference](https://my-mail-ru.github.io/swiftperl/).
