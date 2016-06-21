package SampleXS;

use 5.020002;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('SampleXS', $VERSION);

1;
