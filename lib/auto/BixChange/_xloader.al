# NOTE: Derived from ../../bixchange.cgi.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BixChange;

#line 1140 "../../bixchange.cgi (autosplit into ..\auto\BixChange\_xloader.al)"
sub _xloader {
    use lib qw|. ./lib /lib/cpan|;
    my ($xobj, $pragmas, @params) = @_;

    qx/echo Bx: Enter the _xloader >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};

    #okay to call die in here because we are ALWAYS in an EVAL block
    die('No such XObject as ' . $xobj) unless (-f qq(./lib/$xobj\.pm));
    
    eval(qq(use $xobj qw\/$pragmas\/));
    if ($@ ne '') {
	die("Could not load $xobj because $@");
    }
    my $nObj;
    if (@params > 1) {
     eval (qq(\$nObj = new $xobj\(\@params\))) or die $@;
    } else {
     eval (qq(\$nObj = new $xobj\(\'@params\'\))) or die $@;
    }
    if (defined($nObj)){
	$nObj->{GENERAL} = $bix{'PRIVATE' . $bix{'uniqRUN'}}->{PARENT}->{CFG}->{v}->{GENERAL};
     eval {$nObj->rock()};
      if ($@ ne '') {
        die("XLOADER Error: $@"); 
      } else {
        push @{$bix{'PRIVATE' . $bix{'uniqRUN'}}->{BANK}} , $nObj->roll();
        push @{$bix{'PRIVATE' . $bix{'uniqRUN'}}->{XLOADED}},@{$bix{'PRIVATE' . $bix{'uniqRUN'}}->{BANK}}[-1];
      }
    }
     $nObj->disconnect();
     undef $nObj;
  
     qx/echo Bx: Done _xloading >> $bix{BXTRACEFILE}/ if $bix{BXTRACE}; 

}

# end of BixChange::_xloader
1;
