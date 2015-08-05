# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1049 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_poparchive.al)"
sub _poparchive {
    my ($filename) = @_;
    my $datastring = '';
    $filename = _OS_pathswitch(qq(./data/_archives/$filename));
    if (-f qq($filename\.lock)) {
	open(HANDLE,qq(>$filename\.lock)) or die $!;
        flock(HANDLE,LOCK_EX);
	local($/);
        if (-f qq($filename\.dat)) {
         open(READHANDLE, qq($filename\.dat)) or die $!;
         $datastring = <READHANDLE>;
         close(READHANDLE);
        }
        unlink(qq($filename\.dat));
        flock(HANDLE, LOCK_UN);
        close(HANDLE);
        return $datastring;
    }

}

# end of BixChange::_poparchive
1;
