# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1177 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_validate_user.al)"
sub _validate_user {
    my ($username, $pass, $userFileName) = @_;
    if (!$bix{'PRIVATE' . $bix{'uniqRUN'}}->{USERCHECKS}) {
	$bix{'PRIVATE' . $bix{'uniqRUN'}}->{USERCHECKS} = $userFileName||XINI->new(_OS_pathswitch('./data/u/us/users.ini'));
        $bix{'PRIVATE' . $bix{'uniqRUN'}}->{USERCHECKS}->rock();
        my $rolled = $bix{'PRIVATE' . $bix{'uniqRUN'}}->{USERCHECKS}->roll();
	my @userrecord = grep {$_->{NAME} eq $username} @{$rolled->{USERS}};
        if (@userrecord){
	    if ($userrecord[0]->{PASSWORD} eq crypt($pass,$bix{'UNIVERSALSALT'}||'UNIVERSALSALT')) {
		&initiate_session;
                return $bix{SESSION};
            }
        } else {
            return undef;
        }
    }


}

# end of BixChange::_validate_user
1;
