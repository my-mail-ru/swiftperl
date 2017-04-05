Name:          swiftperl
Version:       %{__version}
Release:       %{!?__release:1}%{?__release}%{?dist}
Summary:       Swift and Perl Interoperability library

Group:         Development/Libraries
License:       MIT
URL:           https://github.com/my-mail-ru/%{name}
Source0:       https://github.com/my-mail-ru/%{name}/archive/%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires: swift >= 3.0.2
BuildRequires: swift-packaging >= 0.6
BuildRequires: swiftpm(https://github.com/my-mail-ru/swift-CPerl.git) >= 0.1.1

%swift_find_provides_and_requires

%description
swiftperl is designed to provide an easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift, though running Perl Interpreter
in Swift environment is also possible.

%{?__revision:Built from revision %{__revision}.}


%prep
%setup -q
echo 'package.targets = package.targets.filter { $0.name != "SampleXS" }' >> Package.swift
echo 'package.exclude.append("Sources/SampleXS")' >> Package.swift
echo 'products = products.filter { $0.name != "SampleXS" }' >> Package.swift
%swift_patch_package


%build
%swift_build


%install
rm -rf %{buildroot}
%swift_install
%swift_install_devel


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%{swift_libdir}/*.so


%package devel
Summary:  Swift and Perl Interoperability module
Requires: swiftperl = %{version}-%{release}
Requires: perl-devel

%description devel
swiftperl is designed to provide an easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift, though running Perl Interpreter
in Swift environment is also possible.

%{?__revision:Built from revision %{__revision}.}


%files devel
%defattr(-,root,root,-)
%{swift_moduledir}/*.swiftmodule
%{swift_moduledir}/*.swiftdoc
