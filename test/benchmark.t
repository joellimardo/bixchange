use Test::More qw(no_plan);
use lib qw|. ./lib ./lib/cpan|;
BEGIN {
  chdir(qq|..|);
}
#tests

use_ok(Benchmark);

#*********************************************************************
#
#  Benchmark tests
#
#*********************************************************************

use Benchmark;
use BixConfig;
use BixChange;

$bix{'uniqRUN'} = Time::HiRes::time();

$BixChange::USESESSIONS = 0;

my $changer = BixChange->new();
$bix{'page_template'} = q|./tmpl/main13.tmpl|;

timethis(100_000,'run_main13');

$got = q|!DOCTYPE HTML|;

like ($got,
      qr|!DOCTYPE HTML|,
       q|Core page is actually there|);


sub run_main13 {
  $changer->show_page('main13');
}

1;
