package XModules;
use strict;
use lib qw/../; 
use vars qw/@ISA/;

use XObjects; 

# $Id: XModules.pm,v 1.1 2007/07/19 03:22:39 joellimardo Exp $


our $VERSION = '0.1';

@ISA = qw/XObjects/;

sub new {
  my ($class, $name) = @_;
  my $self = $class->SUPER::new($name);
  bless $self, $class;
  return($self);
}

sub rock {
    my ($self) = @_;
    $self->add_columns(['MODULE','MODULEPROPER']);
    foreach my $key (keys %INC){
	$self->add_row([$key, $INC{$key}]);

    }
}

sub unload {
    my ($self, $toRemove) = @_;
    use ModPerl::Util;
    ModPerl::Util::unload_package($toRemove);

}


1;
