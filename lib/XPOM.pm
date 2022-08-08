package XPOM;
use strict;
use lib qw/../; 
use vars qw/@ISA/;
use XML::Simple;
use Data::Dumper;
use GDBM_File;
use Fcntl;
use XObjects; 

$XPOM::VERSION = '0.3';

#$XML::Simple::PREFERRED_PARSER = 'XML::Parser';
#$XML::Simple::PREFERRED_PARSER = 'XML::SAX::PurePerl';


@ISA = qw/XObjects/;

sub new {
  my ($class, $name) = @_;
  my $pomName = qq|./DOCS/$name/$name-pom.xml|;
  my $self = $class->SUPER::new($name);
  $self->{POMNAME} = $pomName;
  $self->{POM} = XMLin($pomName);
  bless $self, $class;
  return($self);
}

sub dbmlinks {
    my ($class) = @_;
    my ($pomname) = $class->{NAME};
    my (%D) = ();
    my ($file) = q|./DOCS/| . $pomname . qq|/$pomname-pom.xml|;
    if (-f $file){
        use XML::Simple;
        my $xmlObj = XMLin($file);
        #print Dumper $xmlObj;

        tie (%D,'GDBM_File','./data/' . $pomname . '.gdbm', O_RDWR|O_CREAT,0666);
	#%D = $xmlObj;
        if (ref($xmlObj->{links}->{link} eq 'HASH')) {
          #then there is only one
	    $D{$xmlObj->{links}->{link}->{id}} = $xmlObj->{links}->{link}->{hardlink};
        } else {

	    foreach my $link ($xmlObj->{links}->{link}){
                if ($link->{hardlink}) {
		  $D{$link->{id}} = $link->{hardlink};
	      }else {
                foreach (keys %$link){
		    $D{$_} = $link->{$_}->{hardlink};
                }
	      }
            }
        }
        untie(%D);
    } else {
	die "Cannot find $file\n";
    }
}


sub roll {
    my ($self) = @_;
    return ($self->{POM});

}

1;
