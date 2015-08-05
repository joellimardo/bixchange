package XCut;
use strict;
use lib qw/../; 
use vars qw/@ISA/;

use XObjects; 

# $Id: XCut.pm,v 1.1 2014/08/23 15:48:10 joellimardo Exp $


our $VERSION = '0.1';

@ISA = qw/XObjects/;

sub new {
  my ($class, $name) = @_;
  my $self = {};
  if ((ref $name) && ($name->isa(q|XObjects|))){
      $self = $class->SUPER::new($name->{'NAME'});
      $self->{'ORIGINAL'} = $name;
      $self->{'COLUMNARRAY'} = $self->{'ORIGINAL'}->{'COLUMNARRAY'};
  }
  else
  {  
    $self = $class->SUPER::new($name);
  }
  bless $self, $class;
  return($self);
}

sub rock {
    my ($self) = @_;

    # for the columns specified
    # add ORIGINAL's data
    # then apply blades
    
    die "Column array not set." unless $self->{'COLUMNARRAY'};

    if ($self->{'ORIGINAL'})
    {
         #add all columns from ORIGINAL to this object
         #while adding parse them
	foreach(@{$self->{'ORIGINAL'}->{'ROWS'}})
        {
             # here I need to see if a column exists
             # and if so apply a function that can not only
             # modify the current element but KNOWS about
             # the rest of the values in the row...
             # hence, one has to FEED the current row
             # into the function
	    my $rowRef = $_;
            my %hashCopy = %$rowRef;
            # iterate over the individual blades
            foreach(keys %{$self->{'BLADES'}})
            {
		if($rowRef->{$_})
                {
		   my $newVal = 
		       $self->{'BLADES'}->{$_}->($rowRef, $rowRef->{$_});

                   $hashCopy{$_} = $newVal;
                }
            }
            #push the now modified item into the new object
            # iterate over original column array
            # populate a dummy array
            # use that dummy array when using the standard add_row
            #$self->add_row([\%hashCopy]);

            my @dummy = ();
            foreach(@{$self->{'ORIGINAL'}->{'COLUMNARRAY'}})
            {
		push @dummy, $hashCopy{$_};
            }
	    $self->add_row(\@dummy);

        }
    }

}

sub setBlade {

    my ($self, $field, $subRef) = @_;
    $self->{BLADES}->{$field} = $subRef;
}


1;
__END__
=head1 NAME

XCut

=head1 SYNOPSIS

use XObjects;
use XCut;

my $xobj = XObjects->new('FOO');
$xobj->add_columns([a,b,c,d,e]);
$xobj->add_row([1..5]);

my $xcutter = XCut->new($xobj);

# setBlade can be run multiple times for different columns
$xcutter->setBlade('a',sub{ return qq|xoxox|});
# each blade takes a subroutine and accepts two params
# 1) A hash of the row itself
# 2) the value of the current element
$xcutter->rock();
print Dumper $xcutter;

=cut
