package XPOM;
use strict;
use lib qw/../; 
use vars qw/@ISA/;
use XML::Simple;
use Data::Dumper;
use DB_File;
use Fcntl;
use XObjects; 

# $Id: XPOM.pm,v 1.2 2009/04/14 20:32:51 joellimardo Exp $

$XPOM::VERSION = '0.2';

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

        tie (%D,'DB_File','./data/' . $pomname . '.dbm', O_RDWR|O_CREAT,0666);
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
