#!/usr/bin/perl -wT
use strict;
use CGI qw|:all|;
use Cwd qw|getcwd|;
use lib qw|. ./lib ./lib/auto ./lib/cpan|;
use BixChange;
use BixConfig;
use XTAR;
use Fcntl qw|:flock :DEFAULT|;

#$Id: bixchange.cgi,v 1.9 2014/02/04 21:35:52 joellimardo Exp $

$|++;


BEGIN {
    if ( $^O =~ m/Win32/i ) {

        $ENV{PATH} =
q|c:\\windows\\system32;c:\\WINNT\\System32;c:\\OraNT8i\\bin;c:\\windows\\gnu\\usr\\local\\wbin|
          ;    #change this at your leisure
    }
    else {
        $ENV{PATH} = q!/usr/bin:/bin!;
    }

    use lib qw|. ./lib ./lib/auto ./lib/cpan|;
}

chdir($BixChange::bix{'whereamireally'});

open( STDERR, ">>" . BixChange::_OS_pathswitch('./log/error.log') );

our $VERSION = '$id $';

if ( !$bix{'PERSIST'} ) {
    tie(
        %{ $bix{'PERSIST'} },
        $bix{'DBMFORPERSIST'},
        BixChange::_OS_pathswitch('./data/bixpersist.db'),
        O_RDWR | O_CREAT, 0600
    );

}


$bix{'uniqRUN'} = Time::HiRes::time();

$BixChange::USESESSIONS = 0;

eval {
    my $libpath = BixChange::_OS_pathswitch( $bix{'your_own_libraries'} );
    require "$libpath";
};
if ($@) { BixChange::cgi_die( "User libraries failed to load. " . localtime() . $@ ) }


my $changer = BixChange->new();
my $outputview = '';

#have to deal with POMS straight off because they will affect parameters

my $pom = BixChange::_untaint_param( 'pom', '\S+' );
my $iid = BixChange::_untaint_param( 'iid', '\S+' );
# added for 1.8d
my $usingBxXML = BixChange::_untaint_param( 'BXXML', '\S+' );

if ($pom) {
    my %D;
    my ($pomFname) = qq|./data/$pom.dbm|;
    my $foundid = '';

    tie( %D, 'DB_File', $pomFname, O_RDONLY, 0 );
   
    #if not found outright, grab the one closest to it
    if($D{$iid}=~m/\=/) {$foundid = $iid};
    if (!$foundid)
    {
         foreach ( keys %D ) {
             if (m/^$iid/) { $foundid = $_ }
         }
    }
    if ( $D{$foundid} ) {
        my $objCGI = new CGI( $D{$foundid} );
        if ($objCGI) {

            #I would use $CGI::Q, but that may change in a future version
            foreach ( $objCGI->param() ) {
                if (m/([A-Za-z0-9]+)/) {
                    param( -name => $1, -value => $objCGI->param($_) );
                }
            }
        }
    }

    untie(%D);

}

if ( !defined($changer) ) { BixChange::cgi_die("Cannot create main BixChange object!") }

#get cookies
if ( $INC{'CGI/Cookie.pm'} ) {
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'USERCOOKIES'} =
      BixChange::_getcookies();
}

# added for 1.8d
$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{USINGBXXML} = $usingBxXML;


my @files = grep { m/^[Ff](\d+)?$/ } param();
my $filename = BixChange::_untaint_param( 'tmpl', '\S+(\/\S+)*' ) || '';
my $universe = BixChange::_untaint_param( 'pkg',  '\S+(\/\S+)*' ) || '';

my $tmpl =
  BixChange::_OS_pathswitch( './tmpl/' . $filename . '.tmpl' || '' )
  || $bix{'page_template'};

if ( !-f $tmpl ) {
    $tmpl = q|./tmpl/azure/base.tmpl|;
}

if ( ( defined $universe ) && ( $universe ne '' ) ) {
#here we must verify that the item exists in the universe...if so, then get the actual
#file into a var for further processing
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{UNIV} = $universe;
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{TMPLACTUALBODY} =
      BixChange::_get_universe_data( $universe, './tmpl/' . $filename . '.tmpl' );

}

$bix{'page_template'} = $tmpl;

if ( defined( $files[0] ) ) {
    $bix{'html_die_on_bad_params'} = 0;

    @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{filevals} } =
      map { BixChange::_untaint_param( $_, '\S+(\/\S+)*' ) } sort @files;
    $changer->show_page( @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{filevals} } );

    print $changer->get_output();

}
else
{
  $changer->show_page('main');

  print $changer->get_output();
}
END:
    &BixChange::DESTROY;
1;


