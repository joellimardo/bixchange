# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 984 "../../bixchange.cgi (autosplit into ..\auto\BixChange\persist.al)"
sub persist {
   if ($_[1]){
     if ($_[1] eq 'nix'){
       undef $bix{'PERSIST'}->{$_[0]};
     }
     else
     {
       $bix{'PERSIST'}->{$_[0]} = $_[1];
     }
   }
   else
   {
      return($bix{'PERSIST'}->{$_[0]});
   }
}

# end of BixChange::persist
1;
