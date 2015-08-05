# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1113 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_htendl.al)"
sub _htendl {
  #Think endl in C++, but with the BR type tag
    my ($line)= @_;
    ($line)=~s/\n/\n<BR>/g;
    return $line;
}

# end of BixChange::_htendl
1;
