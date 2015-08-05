# NOTE: Derived from ../user.end.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 27 "../user.end (autosplit into ..\..\lib\auto\BixChange\email_munger.al)"
sub email_munger {
   my ($mail) = @_;
   my $munged = '';
   for(split//,$mail){ $munged .= $_; $munged .= '<SPAN />' x (rand(time)%10) };
   return($munged);
}

1;
1;
# end of BixChange::email_munger
