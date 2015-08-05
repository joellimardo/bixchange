# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1072 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_publishtosubscribers.al)"
sub _publishtosubscribers {
    my ($subscription, $message) = @_;
    my $sfilename = './data/s/su/subscriptions.ini';
    if (-f $sfilename) {
	my $sini = Config::IniFiles->new(-file=>'./data/s/su/subscriptions.ini');
        if (defined($sini->val($subscription,'SUBSCRIPTIONS'))) {
            my @subscriptions = $sini->val($subscription,'SUBSCRIPTIONS');
            foreach my $subs (@subscriptions) {
                if ($subs=~m/(\S+\s*)+/) {$subs = $1;
		    _filearchive($subs, $message)
                   };
            }
        } else {
	    die "NO SUCH SUBSCRIPTION";
        }
        
    }
    return "OK";

}

# end of BixChange::_publishtosubscribers
1;
