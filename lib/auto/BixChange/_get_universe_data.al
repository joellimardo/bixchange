# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1016 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_get_universe_data.al)"
sub _get_universe_data {

    my ($univ, $target) = @_;
    my ($str);
    if (defined($univ) && defined($target)) {
        my $objXTar;
        eval {
	$objXTar = new XTAR(qq|packages/$univ.tar|);
        $str = $objXTar->changeOperation($target);
	 return($str)}
    }


    #if ($@ || ($str eq '')) { cgi_die( "Universe resource failed to load. " . $@ )};



}

# end of BixChange::_get_universe_data
1;
