package DU;

#$Id: Du.pm,v 1.1 2010/08/01 03:38:52 joellimardo Exp $

use strict;
use Tk;
use XML::Simple;
use Data::Dumper;
use Getopt::Long;
use LWP::Simple;

our $gObjName = '$duPackageObj';
our $tFile;
our $parseOK = 0;


sub new {
 my ($self) = {};
    bless ($self);
    return ($self);

}

sub createForm {
my $mw = Tk::MainWindow->new();
my ($self, $tFile) = @_;
 my $xmlString;
 my $duPackageObj = new DU;
if (!defined($tFile)){
  while(<DATA>){
      $xmlString .= $_;
  }
} else {
    local $/;
    if ($tFile){
      if ($tFile !~m/^http/i){
        die "Improper file name $tFile!" if (($tFile) && (!-f $tFile));
        open(CHUNKY,qq|$tFile|) or die "Could not open file! $!"; 
      } else {
        my $httpOutput = get($tFile);
        open(CHUNKY,qq|<|,\$httpOutput);
     }
    }
    $xmlString = <CHUNKY>;
    close(CHUNKY);
}


my $xmlObj = XMLin($xmlString);
print Dumper $xmlObj;
foreach(@{$xmlObj->{contents}->{object}}){
    my $runline = parseProperties($_);
    print qq|$runline\n|;
    eval($runline);
    if ($@){
      print qq|\n\nError:\n\n$@|;
    }
}

# Create Form
$mw->minsize(  $xmlObj->{'length'}->{'value'},
               $xmlObj->{'height'}->{'value'}
            );
eval($xmlObj->{'code'});
if ($@){die $@};

eval('test()');
if ($@){die qq|\nMODULE LOAD ERRORS:\n----------------------\n$@|};

#$mw->title($xmlObj->{'title'}->{'value'});
$parseOK = $xmlObj->{'parseOK'}->{'value'};

if ($parseOK) {
MainLoop;
}
 
}

sub parseProperties {
    my ($object) = @_;
    my $returnLine = '';
    if ($_->{'becomes'}){
	$returnLine .= $gObjName . '->{\'' . $_->{'becomes'} . '\'} = ';
    }
    if (!$_->{'uses'}) {
       $returnLine .= '$mw->' . $_->{type} . '(';
   } else {
       $returnLine .= $gObjName . '->{\'' . $_->{'uses'} . '\'}->' . $_->{'type'} . '(';
   }
    foreach my $prop (keys %{$object->{properties}}) {
        if ($prop ne 'null'){
            if($object->{'properties'}->{$prop}->{minustag} eq 'true'){$returnLine .= '-'};
            if( ($object->{'properties'}->{$prop}->{'raw'}) &&  ($object->{'properties'}->{$prop}->{'raw'} eq 'true')) {
	       $returnLine .= $prop . q|=>| . $object->{'properties'}->{$prop}->{'value'} . ','
            } else {
               $returnLine .= $prop . q|=>"| . $object->{'properties'}->{$prop}->{'value'} . '",'
               
            }
        }
        else
        {
	    $returnLine .= '"' . $object->{'properties'}->{'null'}->{'value'} . '"';
        }
    }     
   $returnLine .= ')';
   $returnLine=~s/FUNCTIONREF\:/\\\&/g;
   return ($returnLine);
}
1;

=head1 DESCRIPTION

You can use this to generate a Perl::Tk form using only XML.

=head1 PROBLEMS

=head2 How do you create multiple forms?

Not sure. Would probably have to run this multiple times for the different XML files. Will need a function
allow them to interact with one another.

=head2 Isn't transferring code like inherently dangerous?

Code signing is the answer.

=head2 Isn't spitting stuff out to the command line crappy?

Yes. Should have a standard method for showing the user that something went wrong as well as a way
to notify the principal developer that an error occurred.

=head2 Where do I put the code?

Added a code node that will be parsed on the fly. 

=head2 Code uses reserved chars

Use a CDATA segment. See the XML below.

=head2 What if the form needs some modules to be installed?

Currently this uses a test() routine in the code segment to check for needed modules. This will spit out a message that a particular module is needed. On Windows you will need to run PPM to get these. On Linux/Unix you can use the CPAN module. If those modules need compiliation, you are on your own.

=cut


__DATA__
<?xml version="1.0" ?>
<DUFORM>
  <length value="300" />

  <height value="300" />
  
  <contents>
    <object type="title" becomes="TITLE">
      <properties>
          <null value="Test Screen 2000" />
      </properties>

    </object>
    <object type="Entry" becomes="ENTRY1">
      <properties>
           <textvariable value="\$entry_val" minustag="true" />
           <show value="*" minustag="true" />
           <takefocus value="1" minustag="true" />
      </properties>
    </object>
    <object type="pack" uses="ENTRY1">
      <properties>
         <side value="top" minustag="true" />
      </properties>
    </object>
    <object type="Entry" becomes="ENTRY2">
      <properties>
           <textvariable value="\$main::entry_val2" minustag="true" raw="true" />
           <show value="*" minustag="true" />
           <takefocus value="1" minustag="true" />        
      </properties>
    </object>
    <object type="pack" uses="ENTRY2">
      <properties>
         <side value="top" minustag="true" />
      </properties>
    </object>

    <object type="Button" becomes="BUTTON1">
     <properties>
       <text value="Enlarge" minustag="true" />
       <command value="FUNCTIONREF:show" minustag="true" raw="true" />
       </properties>
    </object>
    <object type="pack" uses="BUTTON1">
      <properties>
         <side value="top" minustag="true" />
      </properties>
    </object>
  </contents>
  <code>
    <![CDATA[     
     sub show {
	 print $main::entry_val2 . &helloAgain;
     }
     sub helloAgain {
         return 'hello again';
     }
     sub test {
	 my @mods = qw|XML::Simple CGI|;
        foreach my $mod (@mods){
	    my $exline = 'use ' . $mod . ';';
	    eval $exline;
            if ($@){ die $@};
        }
    }
    ]]>
  </code>
  <parseOK value="1" />

</DUFORM>

