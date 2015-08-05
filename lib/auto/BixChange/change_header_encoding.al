# NOTE: Derived from ../user.end.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 14 "../user.end (autosplit into ../../lib/auto/BixChange/change_header_encoding.al)"
sub change_header_encoding 
{
   $BixChange::bix{BixChange::munge_runid('custom_report_header')} = qq|Content-Type:text/html; charset=| . $_[0] . qq|\n\n|;

}

# end of BixChange::change_header_encoding
1;
