#!/usr/bin/perl

use strict;
use warnings;
use SwiftXS;
use TestMouse;
use Devel::Peek;
use Data::Dumper;

my @result = Swift::test(qw/a b c/);
print Dumper(\@result);
Dump($result[0]);
my $obj = TestMouse->new(attr_ro => 88, attr_rw => "FYR");
my @r2 = $result[0]->test(10, $obj);
Dump(\@r2);
print Dumper(\@r2);
eval { warn "Swift::Perl.MyTest"->test2(); 1 } or warn $@;
warn $result[0]->test3("String-String-String", $obj);
sub die_now { die "OLOLO-1" } Swift::test_die();
warn "OK";
