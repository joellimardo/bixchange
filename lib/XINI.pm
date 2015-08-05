package XINI;
use strict;
$XINI::errors = '';

# $Id: XINI.pm,v 1.4 2010/08/26 19:09:29 joellimardo Exp $

use lib qw!.. ./cpan!;

use Config::IniFiles;
use Carp qw/cluck confess croak/;

use vars qw/@ISA/;

use XObjects;

@ISA = qw/XObjects/;

sub new {
    my ( $class, $name, %params ) = @_;

    my $self = $class->SUPER::new($name);
    bless $self, $class;
    if ( $params{hardfile} ) {
        $self->{CFG} =
          Config::IniFiles->new( -rawstring => $name, -allowcontinue => 1 );
        $self->{CFG}->ReadConfig();
    }
    else {
        $self->{CFG} =
          Config::IniFiles->new( -file => $name, -allowcontinue => 1 );
    }
    if ( !defined( $self->{CFG} ) ) {
        $XINI::errors = join( ' ', @Config::IniFiles::errors );
        cluck "Failed to create INI file. " . $XINI::errors;
    }
    $self->{TREE}     = ();
    $self->{RESAVING} = 0;    #false by default
      #columns and rows are already established from the original data structure
    return ($self);
}

sub add_raw_row {
    my ( $self, $rowref, $section ) = @_;
    push @{ $self->{TREE}->{$section} }, $rowref;
}

sub parse_to_structure {
    my ( $self, $BxObj ) = @_;
    my $numrep  = '';
    my $uniqRun = $BixChange::bix{'uniqRUN'};

    qx/echo XINI: Start parse_to_structure >> $BixChange::bix{BXTRACEFILE}/
      if $BixChange::bix{BXTRACE};

#Form adding is handled by adding the necessary functions/actions to the GENERAL section.
#Modifications/deletions are handled by filters and setting a flag that instructs XINI to flush
#everything to a file afterwards.

# store a reference to self in the $bix hash for possible use in _convert_data or _xloader sections
    if (%BixChange::bix) {
        $BixChange::bix{ 'PRIVATE' . $uniqRun }->{PARENT} = $self;
    }
    foreach my $generalkeys ( sort keys %{ $self->{CFG}->{v}->{GENERAL} } ) {

        #join in case the HERE document style entry is being used
        if ( ref( $self->{CFG}->{v}->{GENERAL}->{$generalkeys} ) eq 'ARRAY' ) {
            $self->{CFG}->{v}->{GENERAL}->{$generalkeys} =
              join( qq(\n), @{ $self->{CFG}->{v}->{GENERAL}->{$generalkeys} } );
        }
        if ($BxObj)
        {
	    if (index($self->{CFG}->{v}->{GENERAL}->{$generalkeys},'%%') > -1)
            {
                 $self->{TREE}->{$generalkeys} =
                     $BxObj->_convert_data(
			 $self->{CFG}->{v}->{GENERAL}->{$generalkeys} );
            }
            else
            {
                 $self->{TREE}->{$generalkeys} =
			 $self->{CFG}->{v}->{GENERAL}->{$generalkeys};
            }
        }
        else
        {
            $self->{TREE}->{$generalkeys} =
		 $self->{CFG}->{v}->{GENERAL}->{$generalkeys};
        }

    }

    my @keys;
    my $IniData = $self->{CFG}->{v};

    if (   ( !BixChange::param('sort') )
        || ( !$self->{CFG}->{v}->{GENERAL}->{ BixChange::param('sort') } ) )
    {

        #sort by the loop name and then by the number
        @keys =
          map { $_->[0] }
          sort { $a->[2] cmp $b->[2] || $a->[1] cmp $b->[1] } map {
            [
                $_,
                /LOOP\s+\S+?(\d+(?:\.\d+)*)/,
                /LOOP\s+(\S+?)(?:\d+(?:\.\d+)*)/
            ]
          } grep { /^LOOP/ } keys %{ $self->{CFG}->{v} };
    }
    else {

        @keys = map { $_->[0] } sort {
            eval( $self->{CFG}->{v}->{GENERAL}->{ BixChange::param('sort') } )
          } map { $_ = [ $_, $IniData->{$_} ] }
          grep { /^LOOP/ } keys %{ $self->{CFG}->{v} };
    }

    #First, just dump the general section as is into the mix

    #have to add the session if it exists
    if ( $BixChange::bix{ 'USESESSIONS' . BixChange::get_runid() } ) {

        #session id may already be there, so check first
        if (   ( !$self->{TREE}->{SESSION} )
            && ( $BixChange::bix{ 'SESSION' . BixChange::get_runid() } ) )
        {
            $self->{TREE}->{SESSION} =
              $BixChange::bix{ 'SESSION' . BixChange::get_runid() }->id();
        }
    }

  ROWLOOP:

    foreach my $compkey (@keys)

    {

        foreach my $pkey2proc ( keys %{ $self->{CFG}->{v}->{$compkey} } ) {

            #join up elements that may be on multiple lines
            if (
                (
                    ref( $self->{CFG}->{v}->{$compkey}->{$pkey2proc} ) eq
                    'ARRAY'
                )
                && ( $pkey2proc !~ m/^SUBELEMENTS/ )
              )
            {
                $self->{CFG}->{v}->{$compkey}->{$pkey2proc} = join( qq(\n),
                    @{ $self->{CFG}->{v}->{$compkey}->{$pkey2proc} } );
            }

            #handle elements that need to be evaluated (either by the main
            # if ($self->{CFG}->{v}->{$compkey}->{$pkey2proc}=~m/%%/){

            if ($BxObj)
            {
                 if (index($self->{CFG}->{v}->{$compkey}->{$pkey2proc},'%%') > -1 )
                 {
                    $self->{CFG}->{v}->{$compkey}->{$pkey2proc} =
                       $BxObj->_convert_data(
			   $self->{CFG}->{v}->{$compkey}->{$pkey2proc} );

                 }
                 else
                 {
                    $self->{CFG}->{v}->{$compkey}->{$pkey2proc} =
			$self->{CFG}->{v}->{$compkey}->{$pkey2proc};
                 }
            }
            else
            {
               $self->{CFG}->{v}->{$compkey}->{$pkey2proc} =
		    $self->{CFG}->{v}->{$compkey}->{$pkey2proc};
            }
    
            #}

        }
        if ( $compkey =~ m/^LOOP\s+(\S+?)(\d+(?:\.\d+)*)/ ) {
            $a      = $1;
            $numrep = $2;

            #this processing applies to loops only

            #apply filters here

            $self->{CFG}->{v}->{$compkey}->{'NUMREP'} = $numrep;
            if ( $numrep =~ m/^(\d+)\./ ) {
                $self->{CFG}->{v}->{$compkey}->{PARENT} = $1;
            }
            else {
                $self->{CFG}->{v}->{$compkey}->{PARENT} = $numrep;
            }
            $self->{CFG}->{v}->{$compkey}->{'GROUP'} = $a;
            $self->_next_and_previous( $self->{CFG}->{v}->{$compkey}, \@keys );

            foreach my $filtercode ( @{ $self->{FILTERS} } ) {

     #pass or fail here. If an element fails the filter we simply goto NEXT. The
     #entire row is ignored
                my $untaintedfilter;

                if ( $filtercode =~ m/^(filter\d+)/ ) { $untaintedfilter = $1 }

                #filters may be on multiple lines
                if (
                    ref( $self->{CFG}->{v}->{GENERAL}->{$filtercode} ) eq
                    'ARRAY' )
                {
                    $self->{CFG}->{v}->{GENERAL}->{$filtercode} = join( qq(\n),
                        @{ $self->{CFG}->{v}->{GENERAL}->{$filtercode} } );
                }
                my $val = $self->{CFG}->{v}->{$compkey};
                my $column = $val;    #more aliases for the actual hash
                my $key    = $a;
                next ROWLOOP
                  if (
                    !eval( $self->{CFG}->{v}->{GENERAL}->{$untaintedfilter} ) );
            }

            if ( index( $self->{CFG}->{v}->{$compkey}->{'NUMREP'}, '.' ) == -1 )
            {

                push @{ $self->{TREE}->{$a} }, $self->{CFG}->{v}->{$compkey};
            }

            else {
                if ( $self->{CFG}->{v}->{$compkey}->{'NUMREP'} =~
                    m/^(\d+(\.\d+)*)\.\d+/ )
                {

                  #Must check if the subelements exist prior to the main element
                  #or else you will lose the reference!

                    push @{ $self->{CFG}->{v}->{ 'LOOP ' . qq($a$1) }
                          ->{'SUBELEMENTS'} }, $self->{CFG}->{v}->{$compkey};
                }
            }
        }
    }    #end of for loop

    qx/echo XINI: End parse_to_structure >> $BixChange::bix{BXTRACEFILE}/
      if $BixChange::bix{BXTRACE};

}

sub rock {

    # Override rock
    my ( $self, $BxObj ) = @_;
    qx/echo XINI: rock >> $BixChange::bix{BXTRACEFILE}/
      if $BixChange::bix{BXTRACE};
    $self->parse_to_structure($BxObj);

    #parsing is done, now save if need be
    qx/echo XINI: in Rock(), checking to resave >> $BixChange::bix{BXTRACEFILE}/
      if $BixChange::bix{BXTRACE};
    if ( $self->{RESAVING} ) {
        eval { BixChange::_semaphore_lock_on( $self->{NAME} ) };
        if ( !$@ ) {
            $self->resave();
        }
        BixChange::_semaphore_lock_off();
    }
    qx/echo XINI: end of rock PAGE >> $BixChange::bix{BXTRACEFILE}/
      if $BixChange::bix{BXTRACE};

}

sub roll {

#have to override ROLL because the base object's roll assumes that
#you only have ONE entry to make for the object and with the ability to
#create subloops you will potentially have many more keys in the returned
#hash. Thus, you will have to create them here. Remember to use the add_raw_row
#instead of the more conventional method as it will attempt to associate column headers
#with the actual row data
    qx/echo XINI: Start roll >> $BixChange::bix{BXTRACEFILE}/
      if $BixChange::bix{BXTRACE};
    return ( $_[0]->{TREE} );

}

sub field_untaint {
    my ( $self, $fieldname, $newvalue ) = @_;

    #have to find out the proper name of the item

}

sub _next_and_previous {

    my ( $self, $current_element, $keysref ) = @_;

    #default to current element in case we have a loop with only one element
    $current_element->{NUMREPPREV} = $current_element->{NUMREP};
    $current_element->{NUMREPNEXT} = $current_element->{NUMREP};

    my $i = 0;
    my (%hash) = map { $_ => $i++ } @$keysref;
    my $foundelem =
      $hash{qq(LOOP $current_element->{GROUP}$current_element->{NUMREP})};
    if ( defined($foundelem) ) {

   #if (defined($keysref->[qq(LOOP $current_element->{GROUP}) . $foundelem - 1])
   #     {
   #      $current_element->{NUMREPREV} = $keysref->[$foundelem - 1];
   #      }

        if ( $foundelem != 0 && defined( $keysref->[ $foundelem - 1 ] ) ) {
            $current_element->{NUMREPPREV} = $keysref->[ $foundelem - 1 ];
        }
        if ( defined( $keysref->[ $foundelem + 1 ] ) ) {
            $current_element->{NUMREPNEXT} = $keysref->[ $foundelem + 1 ];
        }

    }

}

sub incr_special {
    my ( $item, $syntax ) = @_;
    my @a = split /\./, $item;
    my @b = split /\./, $syntax;
    my @newrep = map { ( shift @a ) || 0 } @b;
    $newrep[-1]++;
    my $rtval = join( '.', @newrep );
    if ( index( $rtval, '.0' ) > -1 ) {
        return "ERROR: Cannot derive $item from $syntax!\n";
    }
    else {
        return $rtval;
    }
}

sub add {

    #overridden
    my ( $self, $grp, $numrep, $newhashRef ) = @_;
    my $highest =
      ( sort { $a <=> $b }
          map { m/(\d+(?:\.\d+)*)$/; $1 }
          grep { m/LOOP $grp\d+(\.\d+)*/ } keys %{ $self->{CFG}->{v} } )[-1];
    my $numr;
    if ( $numrep !~ m/^\d+/ ) {
        if ( $highest =~ m/^\d+/ ) { $numr = $highest }
        if ($numr) { $numr = incr_special( $numr, $numrep ) }
        else       { $numr = 1 }
    }
    else {
        $numr = $numrep;
    }
    $self->{CFG}->AddSection( 'LOOP ' . $grp . $numr );
    foreach ( keys %{$newhashRef} ) {
        $self->{CFG}->newval( 'LOOP ' . $grp . $numr, $_, $newhashRef->{$_} );
    }
    $self->{CFG}->newval( 'LOOP ' . $grp . $numr, 'NUMREP', $numr );

}

sub delete {
    my ( $self, $group, $numrep ) = @_;
    $self->{CFG}->DeleteSection( 'LOOP ' . $group . $numrep );

}

sub depollute {

    #takes a list of param names and untaints them according to
    #their untaints
    my %rethash;
    my ( $self, $grp, $listref ) = @_;
    my %wanted = map {
        $self->{CFG}->{v}->{$_}->{NAME} => $self->{CFG}->{v}->{$_}->{UNTAINT}
    } grep { m/LOOP\s+$grp\d+(\.\d+)*/ } keys %{ $self->{CFG}->{v} };
    foreach my $elem (@$listref) {
        my $unt = BixChange::_untaint_param( $elem, $wanted{$elem} );
        if ($unt) {
            $rethash{$elem} = $unt;
        }
    }
    return ( \%rethash );
}

sub resave {
    my ($self) = @_;
    my $ret = $self->{CFG}->RewriteConfig();
    return ($ret);
}

=head1 SYNOPSIS

C:\p5httpd_win32\cgi-bin\bixchange\lib>
perl -MData::Dumper -e "$ENV{REQD} = 1; require 'bixchange.cgi'; use XINI; $o=new XINI('c:\temp\functionality.ini'); $o->rock(); print Dumper $o->roll();"

=head1 EXPLANATION

XINI is the heart of this system. It parses INI files, which contain some content and instructions to load other objects in the system. Fear not, the presence of INI files does not indicate a need to work in Windows, even though lots of the development for Bx is primarily done in Windows.

=cut

1;
