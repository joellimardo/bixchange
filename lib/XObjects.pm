package XObjects;

use 5.006;
use strict;
use warnings;

# $Id: XObjects.pm,v 1.1 2009/06/13 16:10:44 joellimardo Exp $

use lib qw|./lib/auto|;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

sub new {
  my ($class,$name) = @_;
  if (!$name){ die 'Name required in XObjects constructor!'};
  my $self = {};
  $self->{COLUMNARRAY} = ();
  $self->{ROWS} = ();
  $self->{NAME} = $name;
  $self->{FILTERS} = ();
  $self->{SELECT} = ();
  bless ($self,$class); 
  return $self;
}

sub add_row {
  my ($self, $rowref) = @_;
  my $good = 1;
  
  my @cols = @{$self->{COLUMNARRAY}};
  my %testhash = map {shift(@cols)=>$_} @$rowref;
  
  foreach my $filter (@{$self->{FILTERS}}) {
    my $val = \%testhash;
    my $column = $val; #conform to filter design standard
    my $key = $self->{NAME};
    if ($filter && (!eval($filter))) {$good = 0};
  }
  if ($good){
     if ($self->{SELECT}) {
       my %newhash;
       for(@{$self->{SELECT}}) {$newhash{$_} = $testhash{$_}}; 
       push @{$self->{ROWS}}, \%newhash;
     } else {
       push @{$self->{ROWS}}, \%testhash;
     }
     
  }
}

sub execute_filters {
    my ($self) = @_;
    my @reviewed; 
    foreach my $datarow (@{$self->{ROWS}}) {
      foreach my $logic (@{$self->{FILTERS}}) {
            my $val = $datarow;
            my $column = $val; #conform to filter design standard
            my $key = $self->{NAME};
 #           if (eval($logic)) {push @reviewed, $datarow};
	    if (!eval($logic)){undef $datarow};
      }
    }
#    $self->{ROWS} = \@reviewed;
}

sub add_raw_row {
  my ($self,$rowref) = @_;
  push @{$self->{ROWS}}, $rowref;
}

sub add_columns {
  my ($self, $colref) = @_;
  my (@cols) = @$colref;
  @{$self->{COLUMNARRAY}} = @cols;
  
}

sub name {
 my ($self, $name) = @_;
 if (!$name) {
    return $self->{NAME};
    } else {
     $self->{NAME} = $name;
    }
}


sub sort {
  #sort all of the rows currently in ROWS
    my ($self) = @_;
    my $sortlogic = $self->{GENERAL}->{BixChange::param('sort')};
    return if (!defined($sortlogic));
    my @sortedelems = sort {eval($sortlogic)} grep {defined($_)} @{$self->{ROWS}};
    if (!$@){
     $self->{ROWS} = \@sortedelems;
    }
   
}

sub rock {
  # You need to subclass this and put your actual code in this. Prior to this operation
  # all parameters of your object will need to exist. This function is called by BixChange
  # without any parameters and will be followed immediately by a call to roll()
  
  

}

sub roll {
 #returns the ROWS inside of a hash along with the name
 my ($self) = @_;
 if (defined($self->{ROWS})) {
 return(   { $self->{NAME}=>$self->{ROWS} }  )} else {
 return(   { $self->{NAME}=>[]})};
}

sub filter {
  my ($self, $filter) = @_;
  if (ref($filter) eq 'ARRAY') { 
    $self->{FILTERS} = $filter;
  } else {
    push @{$self->{FILTERS}},$filter;
  }
  unless (defined(wantarray) ) {return 1};
  return @{$self->{FILTERS}};
}

sub select {

  my ($self, $itemsref) = @_;
  $self->{SELECT} = $itemsref;
  unless (defined(wantarray)) {return 1};
  return $self->{SELECT};
}

1;

sub disconnect {
  #subclass and override this in case you need to

}

sub add {


}

sub modify {


}

sub delete {


}



__END__

=head1 XObjects

bixchange::XObjects - contains the request and response objects for the bixchange system

=head1 SYNOPSIS

   use XObjects;
   my $mmo = new XObjects('FOO'); 
    #if filtering, each column will be filtered at add_row time, so do this first
   $mmo->$o->filter(q(\($key eq 'FOO' && $column->{m} eq 1\)));

   $mmo->add_columns(['m','b','c','f']);  #array ref of column headers
   $mmo->select(['m','c']); #acts like a select in a sql statement, weeding out columns that
                            #are unwanted
                            
   $mmo->add_row([1..4]); #array refs only
   $mmo->add_row([5..8]); #even though select is defined, ALL data defined in add_columns
                          #must be present (for filters, you know)
   
   #the main Bx system is mainly interested in running $mmo->roll()

=head1 DESCRIPTION

XObjects.pm is a base class that allows for a simple way to generate the following structure: 

    Hash of an Array of Hashes (i.e.
          { SOMEKEY => [
                         {itemname1=>'value',itemname2=>'value',itemname3=>'value'}
                         {itemname1=>'value',itemname2=>'value',itemname3=>'value'}
                         {itemname1=>'value',itemname2=>'value',itemname3=>'value'}
                       ] 
           } 
    You can find this covered briefly in the HTML::Template documentation under TMPL_LOOPs. Anyone
    who has had to create this structure more than once is probably begging for a way to do it
    without screwing the thing up, hence this class was born.
    
    The real purpose behind creating this class actually lies in the filter and select functions.
    Anybody can create a hash with arrays of hashes. It is as simple as eval-ing hte structure above.
    What takes time is creating a consistent method for weeding out data that exists in some static
    data structure!
    
    The 'idea' behind this class is to allow for a single function to exist: roll(). The BixChange
    system needs your XObject to be a subclass of XObjects with a roll() function. You can trash
    everything else if you are planning to use a database. In that case the select() and filter() 
    functions are extremely redundant when you can simply pass a select statement directly 
    to your DB. Remember, BixChange was not written to simply work with databases. Having some of 
    the flexibility of using a class that offers similar functionality to ANSI SQL is sort of 
    the idea behind using this system to begin with.
                        
=head1 AUTHOR

Joel.Limardo@forwardphase.com

=head1 SEE ALSO

L<perl>.

=cut
