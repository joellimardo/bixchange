# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1035 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_html_ret.al)"
sub _html_ret {
   my ($retnum) = @_;
   if (!defined($retnum)) {$retnum = 5}; 
   return('<BR>' . '&nbsp;' x $retnum)
}

# end of BixChange::_html_ret
1;
