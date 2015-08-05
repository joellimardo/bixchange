# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1132 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_inherit.al)"
sub _inherit {
 #In a filter that updates data, inherit a field from a parent
    my ($elemref, $keyval) = @_;
    my $objref = $bix{'PRIVATE' . $bix{'uniqRUN'}}->{PARENT}->{CFG}->{v};
    return( $objref->{'LOOP '.$elemref->{'GROUP'} . $elemref->{'PARENT'}}->{$keyval});
}

# end of BixChange::_inherit
1;
