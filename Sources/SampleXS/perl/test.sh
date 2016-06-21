#!/bin/sh

export LD_LIBRARY_PATH=.build/debug
exec perl -ISources/SampleXS/perl/lib Sources/SampleXS/perl/test.pl
