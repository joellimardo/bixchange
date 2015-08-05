# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1094 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_switch_tmpl.al)"
sub _switch_tmpl {

  my ($newtempl) = @_;
  #template resides in $bix{'PRIVATE' . $bix{'uniqRUN'}}->{PAGE}. Presuming all pages listed use the same
  #SITEPACKAGE (should enforce this), one can safely switch the template upon running this
  my $fullfile = _OS_pathswitch(qq(\./tmpl/$newtempl\.tmpl));
  if (-f $fullfile ) {
     $bix{'PRIVATE' . $bix{'uniqRUN'}}->{PAGE} = HTML::Template->new(filename=>$fullfile, die_on_bad_params=>$bix{'html_die_on_bad_params'}); 
     foreach(@{$bix{'PRIVATE' . $bix{'uniqRUN'}}->{BANK}}) {
       $bix{'PRIVATE' . $bix{'uniqRUN'}}->{PAGE}->param($_);
     }
  } else {
   #remember to just die because we are in EVAL
   die("Cannot switch template to $newtempl. It does not exist!");
  }

}

# end of BixChange::_switch_tmpl
1;
