# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1042 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_a_href.al)"
sub _a_href {
  #cannot seem to find a way to write anchors with CGI.pm
  my ($href, $linkname) = @_;
  return qq(<a href = \"$href\" > $linkname </a>);
}

# end of BixChange::_a_href
1;
