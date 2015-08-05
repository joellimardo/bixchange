#!/usr/bin/perl -w
use strict;
#$Id: sessKill.pl,v 1.1 2007/07/20 00:26:02 joellimardo Exp $

chdir('../data/_sessions') or die $!;

my @files = glob('cgisess*');

foreach(@files){
    my  $rat = (stat ($_))[9];
    unlink($_) if ($rat < (time - (60*60*24)));
}

1;
