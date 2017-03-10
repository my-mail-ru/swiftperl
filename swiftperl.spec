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
BuildRequires: perl-devel
BuildRequires: perl-libs

Requires:      perl-libs

%swift_find_provides_and_requires

%description
swiftperl is designed to provide an easy and smooth interoperability between Swift and Perl languages. The primary goal is to write XS modules for Perl entirely in Swift, though running Perl Interpreter in Swift environment is also possible.

%{?__revision:Built from revision %{__revision}.}


%prep
%setup -q
sed -i 's#\(-Xlinker -lperl\)#-Xlinker -L.build/release \1#' prepare
echo 'package.targets = package.targets.filter { $0.name != "SampleXS" }' >> Package.swift
echo 'package.exclude.append("Sources/SampleXS")' >> Package.swift
echo 'products = products.filter { $0.name != "SampleXS" }' >> Package.swift
%swift_patch_package


%build
mkdir -p .build/release
ln -s %{perl_archlib}/CORE/libperl.so .build/release/
%swift_build


%install
rm -rf %{buildroot}
rm -f .build/release/libCPerl.so
%swift_install
%swift_install_devel
# working hard to allow swift interpreter easly import Perl
for f in EXTERN.h perl.h XSUB.h;
	do perl -MConfig -lwe 'print qq!#import \"$Config{installarchlib}/CORE/'$f'"!' > %{buildroot}%{swift_clangmoduleroot}/$f;
done
ln -sf %{perl_archlib}/CORE/libperl.so %{buildroot}%{swift_libdir}/


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%{swift_libdir}/*.so


%package devel
Summary:  Swift and Perl Interoperability module and header files
Requires: swiftperl = %{version}-%{release}
Requires: perl-devel

%description devel
swiftperl is designed to provide an easy and smooth interoperability between Swift and Perl languages. The primary goal is to write XS modules for Perl entirely in Swift, though running Perl Interpreter in Swift environment is also possible.

%{?__revision:Built from revision %{__revision}.}


%files devel
%defattr(-,root,root,-)
%{swift_moduledir}/*.swiftmodule
%{swift_moduledir}/*.swiftdoc
%{swift_clangmoduleroot}/CPerl
%{swift_clangmoduleroot}/*.h
