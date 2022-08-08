#!/usr/bin/perl -wT
#$Id: bixchange.xml.cgi,v 1.6 2014/02/04 19:42:16 joellimardo Exp $

use lib qw|. ./lib ./lib/cpan ./lib/auto|;
use Time::HiRes;
use BixChange;

package BxXML;
@ISA = qw/BixChange/;
use CGI qw/:standard :debug/;
CGI::initialize_globals();

#new stuff
#-------------------------------------------------------
sub develop_body {
    my ($self) = @_;
    my $bodyText = '';
    my $rawFile;
    my $uniqRun = BixChange::get_runid();
    local $/;
    open( HNDL,
        BixChange::_OS_pathswitch(
            BixChange::_studder( $self->{ 'PRIVATE' . $uniqRun }->{'PAGERET'} )
        )
    ) || cgi_die('Unable to open INI file');
    $rawFile = <HNDL>;
    close(HNDL);

    my $cfg = new XINI( $rawFile, hardfile => 1 );
    my $indent = ' ' x 5;

    #this is sub-optimal as it creates a SECOND INI object inside of the
    #bixchange code. The XINI object needs to accept both rawfiles and
    #references to existing XINI objects
    #  $self->remove_reserved($cfg);
    $BixChange::bix{ 'PRIVATE' . $uniqRun }->{CURRENTINI} = $rawFile;
    my $xmlDTD = $cfg->{CFG}->val( 'GENERAL', 'XMLdtd' );
    $bodyText .= $xmlDTD unless ( !$xmlDTD );
    $bodyText .= "<BXRET>\n$indent<UNIQRUN><TMPL_VAR NAME=\"UNIQRUN\"></UNIQRUN>\n";
    $bodyText .=
      "$indent<FILEVAL>" . BixChange::get_private('fileValue') . "</FILEVAL>\n";
    $bodyText .=
        "$indent<SHOULDBE>"
      . $BixChange::bix{ 'PRIVATE' . $uniqRun }->{'fileValue'}
      . "</SHOULDBE>\n";
    $bodyText .= "$indent<FIS>" . BixChange::param('f') . "</FIS>\n";

    #borrowed from XINI

    my @keys = grep { /^TEMPLATE/ } keys %{ $cfg->{CFG}->{v} };
    foreach my $keyname (@keys) {
        my $tmpName = '';
        if ( $keyname =~ m/^TEMPLATE\s+(\w+)/ ) {
            $tmpName = $1;
        }
        $bodyText .= qq|$indent<$tmpName>\n<TMPL_LOOP NAME=\"$tmpName\">\n$indent$indent<ROW>|;
        foreach ( keys %{ $cfg->{CFG}->{v}->{$keyname} } ) {
            $bodyText .= qq|<$_> <TMPL_VAR NAME=\"$_\" /> </$_>\n|;
        }
        $bodyText .= qq|$indent</ROW></TMPL_LOOP></$tmpName>|;
    }

    #$bodyText .= "</BXRET>"; cannot do this in here
    return ($bodyText);
}

sub remove_reserved {
    ( $self, $str ) = @_;
    my $uniqRun = $BixChange::bix{'uniqRUN'};
    $self->{ 'PRIVATE' . $uniqRun }->{BEFOREBODY} = '';    #eliminates warning
    if ( $str =~ m/['"&<>]/ ) {

        #$str=~s/\'/\&apos/g; #[qw|' &apos;|]
        #$str=~s/\"/\&quot;/g; #[qw|" &quot;|]
        #$str=~s/\&/\&amp;/g; #[qw|& &amp;|])

        $str = qq|<![CDATA[| . $str . qq|]]>|;
    }

    #percent symbols are used for evals

    $str =~ s/[^%]%[^%]/\&\#37;/g;

    # < (less than symbols) are used for HERE syntax

    #$str=~s/[^<]<[^<]/\&lt;/g;
    return $str;
}

#overrides
#-------------------------------------------------------
sub cgi_die {
    my ( $self, $msg ) = @_;
    print qq|Content-type: text/xml\n\n|;
    print qq|<BXRET>|;
    print qq|    <ERROR>$msg</ERROR>|;
    print qq|</BXRET>|;

}

sub show_page {
    my ( $self, $page ) = @_;
    my $pgStart = qq|<?xml version="1.0" ?>\n|;
    my $uniqRun = BixChange::get_runid();
    my $indent = ' ' x 5;
    if ( BixChange::param('noheader') ) {
        $BixChange::bix{ 'custom_report_header' . $uniqRun } = qq|\n\n|;
    }
    else {
        $BixChange::bix{ 'custom_report_header' . $uniqRun } =
          qq|Content-type: text/xml\n\n|;
    }
    $BixChange::bix{ 'PRIVATE' . $uniqRun }->{'PAGE'} = undef;
    $self->{ 'PRIVATE' . $uniqRun }->{'PAGERET'} = $page;
    $BixChange::bix{ 'PRIVATE' . $uniqRun }->{'TMPLACTUALBODY'} =
        $pgStart
      . $self->develop_body()
      . qq|\n$indent<GENERATED-ON VALUE=\"|
      . '<TMPL_VAR NAME="XMLGENON">' #let the resource set this
      . qq|\" />\n|
      . qq|$indent<DOCUMENT-SOURCE VALUE=\"|
      . $BixChange::bix{'whereami'}
      . qq|\" />\n</BXRET>\n|;

    #$self->SUPER::show_page($page);
    print ($BixChange::bix{'PRIVATE' . $uniqRun}->{'TMPLACTUALBODY'});

}

sub _convert_data {
    my ( $self, $line ) = @_;

    $line = $self->SUPER::_convert_data($line);
    $line = $self->remove_reserved($line);
    return ($line);
}

#main
#-------------------------------------------------------
package BxXML;

#gotta reset this puppy
$BixChange::bix{'uniqRUN'} = Time::HiRes::time();

my $uniqRun = BixChange::get_runid();

BixChange::set_private( 'fileValue', 'nix' );
BixChange::set_private( 'BxXML',     'nix' );

$BixChange::bix{ 'PRIVATE' . $uniqRun }->{'BxXML'} = new BxXML;
BixChange::set_private( 'fileValue',
    BixChange::_untaint_param( 'f', '[A-Za-z0-9]+' ) );
if (
    ( BixChange::get_private('fileValue') )
    && (
        -f BixChange::_OS_pathswitch(
            BixChange::_studder( BixChange::get_private('fileValue') )
        )
    )
  )
{
    $BixChange::bix{ 'PRIVATE' . $uniqRun }->{'BxXML'}
      ->show_page( BixChange::get_private('fileValue') );
}
else {
    $BixChange::bix{ 'PRIVATE' . $uniqRun }->{'BxXML'}->cgi_die( BixChange::get_private('fileValue') || BixChange::param('f') || ' Not passed-in '
          . ' file not found ' );
}

DESTROY {

    #undef $bix{ 'PRIVATE' . $bix{'PRIVATE' . 'uniqRUN'} };

}

END:

BixChange::DESTROY();

1;

__END__
