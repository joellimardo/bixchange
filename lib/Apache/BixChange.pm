package Apache::BixChange;
use strict;
use Carp;
use warnings;

use CGI qw|:standard|;
use Cwd qw|getcwd|;
use lib q|./lib|;

$ENV{'REQD'} = 1;
use mod_perl();

sub handler {
    chdir(q|./bixchange|);
    require 'bixchange.cgi';
    @Apache::BixChange::ISA = qw|BixChange|;
    my $r = shift;
    my $uniqRun = $BixChange::bix{'uniqRUN'};
   $BixChange::bix{'PRIVATE' . $uniqRun}->{'APACHEREF'} = $r;

=head1 PROBLEM A: Header
  The header can be decided upon dynamically in code. Cannot hard code it here.
=cut

    my $objBx = new BixChange;
    $r->print(header);

=head1 PROBLEM B: PRINT statements
  The final operation of BixChange is to use PRINT to send the output
  to the STDOUT. Seems to work without my overridden methods but not sure that
  is the way it was intended to be used.
=cut

    my @files=  grep {m/^[Ff](\d+)?$/} param();
    my @filevals = map {BixChange::_untaint_param($_,'\S+(\/\S+)*')} @files;
    my $filename = BixChange::_untaint_param('tmpl','\S+(\/\S+)*')||'azure/base';
    $BixChange::bix{'PRIVATE' . $uniqRun}->{'filevals'} = \@filevals;
    my $tmpl = BixChange::_OS_pathswitch('./tmpl/' . $filename . '.tmpl' || '') || '';
    $BixChange::bix{'page_template'} = $tmpl;
    if (defined($files[0]))
    {
      $objBx->show_page(@filevals);
    }
    else
    {
      $objBx->show_page('main');

    }

#    $r->print("<html><body>This will be a Bx body soon!");

END:
    BixChange::DESTROY();
    undef $BixChange::bix{'blowhole'};
    chdir(q|..|);
    return 'HTTP_OK';

}
#-------------------------------------
# OVERRIDES
#-------------------------------------

#None

=head1 INSTALLING

 In the conf/httpd.conf for Mod_Perl 1.0:

 PerlModule Apache::BixChange
  <Location /mod_bixchange>
     SetHandler perl-script
     PerlHandler Apache::BixChange
  </Location>

 
LoadFile "C:/perl/bin/perl56.dll"
LoadModule perl_module modules/mod_perl-eapi-1.so
AddModule mod_perl.c
  
 I placed the actual module in c:/perl/site/lib/Apache/BixChange.pm


=cut


1;
