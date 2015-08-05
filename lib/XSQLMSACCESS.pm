package XSQLMSACCESS; 
use strict;
use lib qw/../; 
use vars qw/@ISA/;
use Win32::ODBC;

use XObjects; 


our $version = '$version$';

@ISA = qw/XObjects/;

sub new {
  my ($class, $name, $sqlstmnt) = @_;
  my $self = $class->SUPER::new($name);
  bless $self, $class;
  $self->{TSQL} = new Win32::ODBC($name);
  if (!defined($self->{TSQL})) {die ('Cannot create Win32::ODBC with this connection string: ' . $name)};
  if (defined($sqlstmnt)) {
   $self->set_sql($sqlstmnt);
  } else {
   $self->{SQLSTATEMENT} = '';  
  } 
  return($self);
}

sub set_sql {
  my ($self, $stmnt) = @_;
  $self->{SQLSTATEMENT} = $stmnt;
  $self->{TSQL}->Sql($stmnt);
  if ($self->{TSQL}->Error()) {die $self->{TSQL}->Error()};
}

sub rock {

 my ($self) = @_;
 while($self->{TSQL}->FetchRow()) {
   my %dhash = $self->{TSQL}->DataHash();
   $self->add_raw_row(\%dhash);
  
 }

}

sub disconnect {
 
 my ($self) = @_;
 $self->{TSQL}->Close();

}



1;
