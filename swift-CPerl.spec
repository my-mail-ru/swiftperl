Name:          swift-CPerl
Version:       %{__version}
Release:       %{!?__release:1}%{?__release}%{?dist}
Summary:       Low-level Swift bindings for Perl

Group:         Development/Libraries
License:       MIT
URL:           https://github.com/my-mail-ru/%{name}
Source0:       https://github.com/my-mail-ru/%{name}/archive/%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires: swift >= 3.0.2
BuildRequires: perl

Provides:      swiftpm(%{url}.git) = %{version}
Requires:      perl-devel

%define debug_package %{nil}

%swift_find_provides_and_requires

%description
swiftperl is designed to provide an easy and smooth interoperability between Swift and Perl languages.
The primary goal is to write XS modules for Perl entirely in Swift, though running Perl Interpreter
in Swift environment is also possible.

%{?__revision:Built from revision %{__revision}.}


%prep
%setup -q


%build
./prepare


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{swift_clangmoduleroot}/CPerl/
cp module.modulemap *.h %{buildroot}%{swift_clangmoduleroot}/CPerl/


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%{swift_clangmoduleroot}/CPerl
