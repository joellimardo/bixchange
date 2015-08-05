use Test::More qw(no_plan);
use lib qw|.. ../lib ../lib/cpan|;

#tests

use_ok(LWP::Simple);

use LWP::Simple;
use BixConfig;
use BixChange;
use Data::Dumper;
use_ok(q|XCut|);
use_ok(q|XObjects|);

my $xobj = XObjects->new('FOO');
$xobj->add_columns([a,b,c,d,e]);
$xobj->add_row([1..5]);

my $xcutter = XCut->new($xobj);

my $got =  '';

# filters actually work for grepping, so addBlades needs to
# work to modify individual columns
$xcutter->setBlade('a',sub{ return qq|xoxox|});
$xcutter->rock();
print Dumper $xcutter;

like ($BixChange::bix{'your_own_libraries'},
      qr|\.\\lib\\user_libs\.pl|,
      q|We can see values in the configuration module|);

1;