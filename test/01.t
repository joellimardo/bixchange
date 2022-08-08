use Test::More qw(no_plan);
use lib qw|.. ../lib ../lib/cpan ../lib/auto|;

#tests

use_ok(BixConfig);
use_ok(BixChange);
use_ok(XINI);
use_ok(HTML::Template);
use_ok(Config::IniFiles);
use_ok(Time::HiRes);
use_ok(Cwd);
use_ok(Fcntl);
use_ok(CGI::Cookie);
use_ok(File::Find);
use_ok(GDBM_File);
use_ok(Data::Dumper);

#verify all the necessary files are in the kit


eval{my $bxc = BixConfig->new()};

like($@,
     qr|\QCan't locate object method "new" via package "BixConfig"|,
     q|You don't use new() for BixConfig|);

eval 
{
  open(TST, ">>../log/dummy.log") or die $!;
  close(TST);
};


like ($@,
      qr|^$|,
      q|Okay to create logfiles in logfile directory|);

# you have to manually set up the %bix hash uniqRUN item
$BixChange::bix{'uniqRUN'} = Time::HiRes::time();

like (BixChange::get_runid(),
      qr|$BixChange::bix{'uniqRUN'}|,     
       q|Run_Id gives us the uniqRUN|);

like (BixChange::get_runid(),
      qr|\d+|,
       q|BixChange::get_runid() works|);

like (BixConfig::RunValue('abba','beta'),
      qr|beta|,
       q|Runvalue works okay|);

# test some base autoloaded routines      

chdir(qw|..|) or die $!;

my $output = BixChange::_html_ret();

like ($output,
      qr|\<BR|,
       q|Autoload works!|);

$output = $BixChange::bix{'VERSION'};

like($output,
      qr|1.8g|,
       q|Proper version number set|);

BixChange::persist('SMILES',100);
 
like(BixChange::persist('SMILES'),
     qr|100|,
      q|Persistence works|);

BixChange::persist('SMILES',100.234);

like(BixChange::persist('SMILES'),
     qr|100.234|,
      q|Persistence works with floats|);

my  %newhash = ('a'=>50,'b'=>99);
 
BixChange::persist('SMILES',
                    \%newhash);

like(BixChange::persist('SMILES'),
     qr|100.234|,
      q|In persistence reuse the non-hash wins|);

my $hashref = $BixChange::bix{'DBPERSIST'};

like ($hashref->{'SMILES'}->{'b'},
      qr|99|,
       q|Here is where it went|);

BixChange::persist('UNUSED',\%newhash);

like(BixChange::persist('UNUSED')->{'b'},
     qr|99|,
      q|Correct usage|);

my $flat = Data::Dumper->Dump([\%newhash],[qw|$newhash|]);

BixChange::persist('THIRD',$flat);

my $proof = BixChange::persist('THIRD');

eval($proof);

$newhash = $newhash; #eliminates warning

like($newhash->{'b'},
     qr|99|,
      q|Flattened version workaround works|);

chdir(q|./test|) or die $!;


#cleanup

if (-f '../log/dummy.log')
 {
    unlink '../log/dummy.log';
 }


1;
