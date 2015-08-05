package XCSV; 
use strict;
use Text::CSV; 
use lib qw/../; 
use vars qw/@ISA/;

use XObjects; 

# $Id: XCSV.pm,v 1.1 2007/07/19 03:19:23 joellimardo Exp $


our $version = '$version$';

@ISA = qw/XObjects/;

sub new {
  my ($class, $name) = @_;
  my $self = $class->SUPER::new($name);
  bless $self, $class;
  $self->{TCSV} = new Text::CSV;
  
  return($self);
}

sub load_file_data {
  my $self = shift;
  my $filename = BixChange::_OS_pathswitch('./data/_csv/') . $self->{'NAME'} . '.csv';
  if (!-f $filename) {die("Cannot locate file: $filename")};
  open(H,$filename)||die("Cannot open $filename");

  @{$self->{FILEDATA}} = <H>;

  close(H);
  $self->{TCSV}->parse(@{$self->{FILEDATA}}[0]);
  $self->add_columns([$self->{TCSV}->fields]);
}


sub rock {

 my ($self) = @_;
 $self->load_file_data();
  my @filters = grep {(m/^filter\d+/i) && (BixChange::param($_) eq 'on')} BixChange::param();
  if (@filters) {
    $self->filter([map {(ref($_) eq 'ARRAY')? join(' ',$_) : $_ } map {$self->{GENERAL}->{$_}} map {$_=~m/^(filter\d+)/; $1} @filters]);
        }
  $self->add_csv_rows();

}

sub add_csv_rows {
   my $self = shift;
   my @rows = @{$self->{FILEDATA}};
   for(1..$#rows) {
     $self->{TCSV}->parse($rows[$_]);
     $self->add_row([$self->{TCSV}->fields]);
   }

}



1;
