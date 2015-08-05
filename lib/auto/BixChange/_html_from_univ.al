# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1001 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_html_from_univ.al)"
sub _html_from_univ {
    my ($univ, $target ) = @_;
    my $bodyText = _get_universe_data($univ, $target);
    my $aRef = HTML::Template->new_scalar_ref(\$bodyText, die_on_bad_params=>$bix{'html_die_on_bad_params'});
    return $aRef;
 }


# end of BixChange::_html_from_univ
1;
