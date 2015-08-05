#!/usr/bin/perl -w
use Test::Harness;

my @files = glob(q|*.t|);

runtests(@files);

1;
