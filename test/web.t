use Test::More qw(no_plan);
use lib qw|.. ../lib ../lib/cpan|;

#tests

use_ok(LWP::Simple);

#*********************************************************************
#
#  These are tests that will use LWP::Simple against a localhost
#  webserver. Only run these when your server is up and running
#
#*********************************************************************

use LWP::Simple;
use BixConfig;
use BixChange;

my $got =  '';


like ($BixChange::bix{'your_own_libraries'},
      qr|\.\\lib\\user_libs\.pl|,
      q|We can see values in the configuration module|);

my $whereami = $BixChange::bix{'whereami'};

$got = get(qq|$whereami/bixchange.cgi|);

like ($got,
      qr|!DOCTYPE HTML|,
       q|Core page is actually there|);

$got =
get(qq|$whereami/bixchange.cgi?f=helloworld;tmpl=helloworld;pkg=test-v0.1|);

like ($got,
      qr|WORLD|,
       q|Universes work correctly|);


$got =
get(qq|$whereami/bixchange.cgi?f=helloworld;tmpl=helloworld;pkg=test-v0.3|);

like ($got,
      qr|HELLO WORLD|,
       q|Universes (TAR mode) work correctly|);


$got =
get(qq|$whereami/bixchange.cgi?f=main14;tmpl=13|);

like ($got,
      qr|10000|,
       q|Set/Get Private works|);


$got =
get(qq|$whereami/bixchange.cgi?f=main13;tmpl=main13|);

like ($got,
      qr|\d+|,
       q|GET_RUNID() works|);

$got =
get(qq|$whereami/bixchange.cgi?f=main2|);

like ($got,
      qr|600|,
       q|General parameter override function|);



$got =
get(qq|$whereami/bixchange.cgi?f=main9;tmpl=main9|);

like ($got,
      qr|ikoiko|,
       q|Cookies working|);

my $random = rand();

$got =
get(qq|$whereami/bixchange.cgi?f=main10;tmpl=azure/main10;NEWELEM=$random;NEWELEMVALUE=$random;GROUP=STUFFCREATED;NUMREP=x|);

like ($got,
      qr|$random|,
       q|Update resource files ok|);

$got =
get(qq|$whereami/bixchange.cgi?f=main;f1=main3;tmpl=main3|);

like ($got,
      qr|9002|,
       q|Multi-file resource test working|);

$got =
get(qq|$whereami/bixchange.cgi?f=main22;tmpl=main19|);

like($got,
     qr|okay\?\s+\S+|,
      q|Session is okay for user|);
