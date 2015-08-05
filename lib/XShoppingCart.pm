package XShoppingCart; 
use strict;
use lib qw/../; 
use vars qw/@ISA/;

use XObjects; 

# $Id: XShoppingCart.pm,v 1.1 2007/07/19 03:23:38 joellimardo Exp $


our $version = '$version$';

@ISA = qw/XObjects/;

sub new {
  my ($class, $name, $ref2session, $dbconn) = @_;
  my $self = $class->SUPER::new($name);
  bless $self, $class;
  $BixChange::bix{USESESSIONS} = 1;
  if (!$ref2session) {
      &BixChange::initiate_session;
      $ref2session = $BixChange::bix{SESSION};
  }
  $self->{SESSIONREF} = $ref2session unless (!defined $ref2session);
  $self->{DBCONN} = $dbconn||undef;
  return($self);
}

sub rock {
    my ($self)= @_;
    my $total = 0;
    if (defined $self->{SESSIONREF}) {
     if (defined $self->{SESSIONREF}->param('CARTCONTENTS')) {
        foreach( values %{$self->{SESSIONREF}->param('CARTCONTENTS')} ) {
            if($_->{'price'}) { $total += ($_->{'price'} * $_->{quantity})};
	    $_->{SESSIONID} = $self->{SESSIONREF}->id();
            $self->add_raw_row($_);
        }
      } else {
	  $self->add_raw_row({sku=>'00000',price=>0,name=>'No items in cart'});
      }
  
    } else {
	die "No session object";
    }
    $self->add_raw_row({'TOTAL'=>$total});
}

sub add {
 #override
    adding(@_);
}

sub adding {
         my ($self)= @_;
         my $retmess = '';
         my @items = grep {m/sku\d+/} BixChange::param(); 
         foreach(@items){
            if(BixChange::_untaint_param(qq(quant$_),'\d+')){
             my $cart = $self->{SESSIONREF}->param('CARTCONTENTS');
             if (!defined $cart){
               $self->{SESSIONREF}->param('CARTCONTENTS', {});
             }
            if ($self->{SESSIONREF}->param('CARTCONTENTS')->{$_}) {$retmess = 'Item already exists in cart.'}
            else {
                
                $self->{SESSIONREF}->param('CARTCONTENTS')->{$_} = {sku=>$_, name=>BixChange::_untaint_param($_,'(?:\S+\s*)*'), quantity=>BixChange::_untaint_param('quant' . $_, '\d+'), price=>BixChange::_untaint_param('price','\d+(?:\.\d\d)?')};

              $retmess = 'Item successfully added.';}
                 }
           }
          $retmess;
}

sub modify {
    my ($self, $sku, $newamount) = @_;
    die "Cannot modify without sku and newamount in XShoppingCart::modify " unless ((defined $sku)  && (defined $newamount));
     if ($self->{SESSIONREF}->param('CARTCONTENTS')->{'sku' . $sku}){
	 $self->{SESSIONREF}->param('CARTCONTENTS')->{'sku' . $sku}->{'quantity'} = $newamount;
     }    

}

sub delete {
    my ($self, $sku) = @_;
    if ($self->{SESSIONREF}->param('CARTCONTENTS')->{'sku' . $sku}) {
	delete $self->{SESSIONREF}->param('CARTCONTENTS')->{'sku' . $sku};
    }
}


sub clear_cart {
    my ($self) = @_;
       if ($self->{SESSIONREF}->param('CARTCONTENTS')) {
	   $self->{SESSIONREF}->param('CARTCONTENTS',{});
       }

}


1;
