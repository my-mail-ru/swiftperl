#!/bin/sh

export LD_LIBRARY_PATH=.build/debug
exec perl -Iperl/lib perl/test.pl
