package XTAR; 
use strict;

use lib qw/../; 
use vars qw/@ISA/;

use XObjects; 
use XINI; 

# $Id: XTAR.pm,v 1.1 2007/07/19 03:24:44 joellimardo Exp $


our $version = '$Id: XTAR.pm,v 1.1 2007/07/19 03:24:44 joellimardo Exp $';

@ISA = qw/XObjects/;

sub new {
  my ($class, $name) = @_;
  my $self = $class->SUPER::new($name);
  bless $self, $class;
  $self->{READSTRING} = 'tar -xf <TARFILENAME> <FILENAMEIWANT> -O';
  $self->{RAWPASSED} = $name;
  $self->{TARFILENAME} = (-f $name)? $name : '';
  $self->{FILENAMEIWANT} = ''; 
  $self->{FORMKEYS} = ();
  return($self);
}


sub changeOperation {
    my ($self, $filename) = @_;
    if (defined($filename)) {
	$self->{FILENAMEIWANT} = $filename;
    }
    if ($self->{'TARFILENAME'} eq '')
    {
        my $rawpassed = $self->{'RAWPASSED'};
        $rawpassed=~s/\.tar$//;
        if (-d $rawpassed)
	{
            #This is a directory
            my  $ext;
             if( $self->{'FILENAMEIWANT'}=~m/[^\\\/]+\.(\S+)$/)
	     {
		 $ext = $1;
             }
            if (($ext) && ($BixChange::bix{'FILEPATHMAP'}->{$ext}))
            { 
                my $output = '';
                my $fullpath = $self->{'FILENAMEIWANT'};
                if ($BixChange::bix{'FILEPATHMAP'}->{$ext}=~m/\<\<\<studder\>\>\>/)
		{
                    $fullpath =~s!^\.\/!\.\/$rawpassed\/!;
                }
                else
                {
                    $fullpath = $self->{'FILENAMEIWANT'};
                    $fullpath=~s/^\.\///;
                    $fullpath = $rawpassed . '/' . $fullpath;
		}
 
                $fullpath = BixChange::_OS_pathswitch($fullpath);

                open(HNDL, $fullpath) or die $!;
                 while(<HNDL>)
		 {
		     $output .= $_;
                 }
                close(HNDL);
                return ($output);
            }
        }
    }
    if ($self->{'TARFILENAME'} && $self->{'FILENAMEIWANT'}) {
	my $dField = $self->{READSTRING};
        $dField=~s/\<TARFILENAME\>/$self->{TARFILENAME}/xg;
        $dField=~s/\<FILENAMEIWANT\>/$self->{FILENAMEIWANT}/xg;
        return (`$dField`);
    }
   

}

sub rock {

}

sub roll {

}



1;
