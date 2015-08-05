
package BixChange;

use 5.008008;
use strict;
use warnings;
use AutoLoader;
use Time::HiRes;
use Cwd qw/getcwd/;
use Fcntl qw(:flock :DEFAULT);
use CGI qw/:standard :debug /;
use CGI::Cookie;
use HTML::Template;
use File::Find;
use DB_File;

require Exporter;
require BixConfig;
require XINI;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [qw( )] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(%bix);
our ($AUTOLOAD);

our $VERSION = '$Revision: 1.6 $';

our %bix;
our ($SESSIONID);
our ($PRIVATE);
our ($USESESSIONS);
our ($USER);
our ($CUSTOM_REPORT_HEADER);

# Preloaded methods go here.
#Id: $

sub AUTOLOAD {
    my ($sub) = $AUTOLOAD;
    $sub =~ s/^BixChange:://;
    $sub =~ s/::/\//;

    my $filename = _OS_pathswitch(qq|./lib/auto/BixChange/$sub|) . qq|\.al|;
    if ( -f $filename ) {
        require $filename;
        no strict 'refs';
        goto &$sub;
    }
    else {
        goto &AutoLoader::AUTOLOAD;
    }

}


sub get_output {
    my ($self) = @_;
    return ($self->{'OUTPUT'});
}


sub show_page {

    qx/echo Bx: SHOWING PAGE >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};

    my ( $self, @files ) = @_;
    my $time     = localtime;
    my $file_val = shift @files;

    push @{ $bix{LOGCACHE} },
"Running $file_val with $bix{'page_template'} at $time from $ENV{'REMOTE_ADDR'}\n"
      if ( $ENV{'REMOTE_ADDR'} );

    my @patharr = split //, $file_val;

    #studder the filepath
    my $filepath =
        qq(./data/)
      . lc( $patharr[0] ) . '/'
      . lc( $patharr[0] )
      . lc( $patharr[1] )
      . qq(/$file_val.ini);    #format is ./data/m/ma/main.ini for example

    my $refresh_speed = $bix{'refresh_speed'};
    if (
        ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{UNIV} )
        || (
            !(
                $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CURRENTINI} =
                _get_universe_data(
                    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{UNIV}, $filepath
                )
            )
        )
      )
    {
        if ( !-f _OS_pathswitch($filepath) ) { cgi_die("$file_val not found") }
    }

    if (   ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{TMPACTUALBODY} )
        && ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{TMPLACTUALBODY} eq '' ) )
    {
        if (   ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'} )
            && ( !-f _OS_pathswitch( $bix{'page_template'} ) ) )
        {
            cgi_die(
"PAGE TEMPLATE $bix{'page_template'} points to a non-existent file!"
            );
        }
    }
    my $cfg;
    if ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CURRENTINI} ) {
        $cfg = new XINI( _OS_pathswitch($filepath) );
    }
    else {

        $cfg = new XINI( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CURRENTINI},
            hardfile => 1 );

    }

    cgi_die('Unable to load XINI!') if ( !defined($cfg) );
    cgi_die( 'Error in data ' ) if ( !defined( $cfg->{CFG} ) );
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{HEADERTYPE} ||=
      $cfg->{CFG}->val( 'GENERAL', 'PAGETYPE' );
    if ( $bix{'page_template'} =~ m/base\.tmpl/ ) {
        if ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'} ) {
            $bix{'page_template'} =
              _OS_pathswitch( $cfg->{CFG}->val( 'GENERAL', 'DEFAULTTEMPLATE' ) )
              || $bix{'page_template'};
        }
        else {
            if (   ( !$bix{ 'PRIVATE' . get_runid() }->{'TMPLACTUALBODY'} )
                && ( $cfg->{CFG}->val( 'GENERAL', 'DEFAULTTEMPLATE' ) ) )
            {
                $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'TMPLACTUALBODY'} =
                  _get_universe_data(
                    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'},
                    _OS_pathswitch(
                        $cfg->{CFG}->val( 'GENERAL', 'DEFAULTTEMPLATE' )
                    )
                  );
            }
        }
    }

    if ( $cfg->{CFG}->val( 'GENERAL', 'REFRESHSPEED' ) ) {
        $refresh_speed = $cfg->{CFG}->val( 'GENERAL', 'REFRESHSPEED' );
    }
    $bix{'refresh_speed'} = $refresh_speed;

    if ( $cfg->{CFG}->val( 'GENERAL', 'SITEPACKAGE' ) ) {

        #load site specific code
        if ( !$self->{SITEPACKAGE}
            ->{ $cfg->{CFG}->val( 'GENERAL', 'SITEPACKAGE' ) } )
        {

            #add the site package
            $self->{SITEPACKAGE}
              ->{ $cfg->{CFG}->val( 'GENERAL', 'SITEPACKAGE' ) } = 'loaded';
            push @files, $cfg->{CFG}->val( 'GENERAL', 'SITEPACKAGE' );
        }

        #inis
        #filters

    }
    my $aRef;
    if (
        (
               ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{TMPLACTUALBODY} )
            && ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{TMPLACTUALBODY} ne '' )
        )
        && ( !defined( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{PAGE} ) )
      )
    {
        my $bodyText = $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{TMPLACTUALBODY};
        $aRef =
          HTML::Template->new_scalar_ref( \$bodyText,
            die_on_bad_params => $bix{'html_die_on_bad_params'} )
          or cgi_die($!);

    }
    my $page =
         $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{PAGE}
      || $aRef
      || HTML::Template->new(
        filename          => $bix{'page_template'},
        die_on_bad_params => $bix{'html_die_on_bad_params'}
      );

    $page->param( $self->apply_filters($cfg) );

    #Handle XLOADED sections

    foreach
      my $xloadedref ( @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{XLOADED} } )
    {

        $page->param($xloadedref);
    }

    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CFG} =
      $cfg->{CFG};    #cache for later destruction

    if ( !@files ) {

        $self->{'OUTPUT'} = $self->show_header();

        $self->{'OUTPUT'} .= $self->push_page_output(
            ( defined( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'PAGE'} ) )
            ? \$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'PAGE'}
            : \$page );
        #return(\$outputview);
      # goto END;    

    }
    else {

        #don't run here. Recurse
        $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{PAGE} = $page;
        $self->show_page(@files);
    }

    qx/echo Bx: END OF SHOWING PAGE >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};
    #return(\$outputview);
}


sub new {
    my ($class) = @_;
    CGI::initialize_globals();
    my $self = { HEADER_TYPE => '',
                 OUTPUT=>'' };
   
    bless $self, $class;
    return $self;
}


sub cgi_die {

    #death pages shouldn't be ugly
    my ( $self, $msg ) = @_;
    my $outputview = '';
    my $deathpage;
    if($msg) 
    {
       $outputview = $self->_print_b_header('ERROR');
    }
    else
    {
       $outputview = _print_b_header('ERROR');
    } 
    if   ( @_ == 1 ) { $msg = $_[0] }
    else             { $msg = $_[1] }
    if ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'} ) {
        $deathpage =
          HTML::Template->new(
            filename => _OS_pathswitch('./tmpl/first.tmpl') );
    }
    else {
        $deathpage =
          _html_from_univ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'},
            './tmpl/first.tmpl' );
    }
    $deathpage->param( 'ERROR_MESSAGE' => $msg );
    return($outputview||$deathpage->output());
    #goto END;    #p5httpd_win32 dies if you use exit()

}


sub push_page_output {

    qx/echo Bx: Pushing page output >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};

    my ( $self, $pageref ) = @_;
    my $othertagsref = $bix{'bixtags'};
    my $tag;
    foreach $tag ( keys %$othertagsref ) {
        $$pageref->param( $tag => $othertagsref->{$tag} );
    }

    qx/echo Bx: Calling output on HTML::Template >> $bix{BXTRACEFILE}/
      if $bix{BXTRACE};
    my $oVal = _untaint_param( 'tmpl2', '\S+' ) || '';
    my $possTrans = _OS_pathswitch('./tmpl/') . $oVal . '.tmpl';
    if ( !-f $possTrans ) {

        return($$pageref->output());

    }
    else {
        my $newTemplate;

        #transformation mode
        if ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'} ) {
            $newTemplate = HTML::Template->new( filename => $possTrans );
        }
        else {
            $newTemplate =
              _html_from_univ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'UNIV'},
                $possTrans );
        }

        # had a strange bug...calling param() first seemed to fix, so...
        my @junk = $newTemplate->param();    #reinitialize this?
        my $pRes = $$pageref->output();
        my ( $cleanStr, $cleanRes );
        if ( $pRes =~ m/(.*)/sg ) { $cleanStr = $1 }
        if ($cleanStr) {
            $cleanRes = eval($cleanStr);
        }
        if ( !$@ ) {

            $newTemplate->param($cleanRes);
            return($newTemplate->output());

        }
        else {
            cgi_die( "Unable to perform transformation: " . localtime() . $@ );
        }
    }

    qx/echo Bx: End of push_page_output >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};
}



sub apply_filters {
    my ( $self, $cfg ) = @_;

    qx/echo Bx: Start applying_filters >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};

    my @filters =
      grep { (m/^filter\d+/i) && ( BixChange::param($_) eq 'on' ) }
      BixChange::param();
    if (@filters) {
        $cfg->filter( \@filters );
    }
    $cfg->rock($self);
    push @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{BANK} }, $cfg->roll();

    qx/echo Bx: Done applying_filters >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};

    return ( @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{BANK} }[-1] );

}


sub show_header {
    my ($self) = @_;
    my $header = '';
    qx/echo Bx: Start show_header >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};

    my $header_type = $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'HEADERTYPE'};
    if ( defined($header_type) && ( $header_type =~ m/FORM/i ) ) 
    {
       $header =  _print_b_header('FORM');
    }
    else { $header = _print_b_header('') }

    qx/echo Bx: Done with show_header >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};
    return ($header);
}

#-------------------------------------------------------
#                UTILITY FUNCTIONS
#-------------------------------------------------------


sub _OS_pathswitch {
    my ($path) = @_;
    ( $^O =~ /^MSWin32/ ) ? $path =~ s/\//\\/g : $path =~ s/\\/\//g;
    return ($path);
}


sub _print_b_header {
    my $self;
    if ( ref( $_[0] ) eq 'HASH' ) { $self = shift @_ }
    my $uniqRun = get_runid();
    my $header = '';
    my ( $type, $refresh_speed ) = shift @_;
    if ( !($refresh_speed) ) { $refresh_speed = $bix{'refresh_speed'} }

    if ( $bix{ 'custom_report_header' . $uniqRun } ) {

        $header = $bix{ 'custom_report_header' . $uniqRun };

    }
    else {
        if ($bix{'PRIVATE' . $bix{'uniqRUN'}}->{USINGBXXML})
        {
	    $header = qq~Content-Type: text/xml\n\n~;
        }
        else
        {
             $header = header(
                 -cookie => $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{COOKIEJAR} );

             if ( ( $type eq "ERROR" ) || ( $refresh_speed == 0 ) ) {

             #don't automatically refresh error messages

             }
             elsif ( $type eq "FORM" ) {

             #don't automatically refresh forms
             }
             else {

                 $header .=
                    '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">';
            $header .= "<META HTTP-EQUIV=\"refresh\" CONTENT=\"$refresh_speed\">";
             }
	}

    }
    return($header);
}


sub _convert_data {

    #-------------------------------------------------------------------
    # detects if an eval statement exists in the ini file and parses it
    # before moving the data to the template output
    #-------------------------------------------------------------------
    my ( $self, $line ) = @_;
    if ( ( !$line ) && ( ref( \$self ) eq 'SCALAR' ) ) {
        $line = $self;
    }
    if ( $line =~ /%%/ ) {

        #$line=~s/%%\s*([^%]+)\s*%%/$1/meeg;
        $line =~ s/%%(.+?)%%/$1/meegs;
    }
    if ($PRIVATE) {
        if ( ($@) and $bix{'die_on_bad_ini_evals'} ) {
            cgi_die("Die on parsing "
                  . $PRIVATE->{'CLEANVALUES'}->{'f'}
                  . " resource file eval: "
                  . localtime()
                  . $@ );
        }
    }
    else {
        if ( ($@) and $bix{'die_on_bad_ini_evals'} ) {
            cgi_die( "Die on parsing .ini file eval: " . localtime() . $@ );
        }
    }
    return ($line);

}


sub _bankdeposit {
    my ($hahRef) = @_;
    push @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{BANK} }, $hahRef;
    push @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{XLOADED} },
      @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{BANK} }[-1];
}


sub _bankpeek {
    my ($imafter) = @_;
    my $ret;

    my @from = @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'BANK'} }
      if ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'BANK'} );
    foreach (@from) {
        if ( defined( $_->{$imafter} ) ) { $ret = $_->{$imafter} }
    }
    return ($ret);
}


sub _bankpeek_general {
    my (%peeks) = @_;
    foreach ( keys %peeks ) {
        if ( !BixChange::_bankpeek($_) ) {
            BixChange::_general_param( $_, $peeks{$_} );
        }
    }

}



sub _bxstore {

    my ( $name, $val ) = @_;

    if ( defined($val) ) {
        $BixChange::bix{ 'USER' . $bix{'uniqRUN'} }->{$name} = $val;
    }
    else {
        return $BixChange::bix{ 'USER' . $bix{'uniqRUN'} }->{$name};
    }

}


sub _general_param {
    my ( $fieldname, $newvalue ) = @_;

#1.8b: overwrite BOTH values
#the value may already have been moved to the TREE hash
#if (($newvalue) && ($bix{'PRIVATE' . $bix{'uniqRUN'}}->{PARENT}->{TREE}->{$fieldname})) {
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{PARENT}->{TREE}->{$fieldname} =
      $newvalue;

    # }else {
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{PARENT}->{CFG}->{v}->{GENERAL}
      ->{$fieldname} = $newvalue
      unless ( !defined($newvalue) );

    #shouldn't this untaint this if possible?
    return $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{PARENT}->{CFG}->{v}->{GENERAL}
      ->{$fieldname};

    #}

}

sub initiate_session {
    if ( $bix{ 'USESESSIONS' . get_runid() } ) {
        eval('use CGI::Session');
        if ( !$@ ) {
            my $sessfile = $_[0]
              || _untaint_param( 'sessionid', '[A-Za-z0-9]+' );
            $bix{ 'SESSION' . get_runid() } =
              CGI::Session->new( $bix{CGISESSIONDRIVER}, $sessfile,
                { Directory => _OS_pathswitch( $bix{CGISESSIONPATH} ) } );

            #quick check
            if (
                -f _OS_pathswitch(
                    $bix{CGISESSIONPATH} . '/cgisess_' . $sessfile
                )
                && ( $bix{ 'SESSION' . get_runid() } )
                && ( $sessfile ne $bix{ 'SESSION' . get_runid() }->id() )
              )
            {
                die
"Session file exists but CGISESSION cannot initiate! Your session id is $sessfile but you will get "
                  . $bix{ 'SESSION' . get_runid() }->id()
                  . $bix{ 'SESSION' . get_runid() }->error();
            }
            if ( $bix{ 'SESSION' . get_runid() } ) {
                if ( $bix{ 'SESSION' . get_runid() }->param('-accesscount') ) {
                    $bix{ 'SESSION' . get_runid() }->param( '-accesscount',
                        $bix{ 'SESSION' . get_runid() }->param('-accesscount') +
                          1 );
                    if ( $bix{ munge_runid('SESSION') }->remote_addr() ne
                        $ENV{'REMOTE_ADDR'} )
                    {
                        BixChange::cgi_die( 'Session not valid for '
                              . $ENV{'REMOTE_ADDR'}
                              . ', SESSION '
                              . $bix{ munge_runid('SESSION') }->id()
                              . ' REMOTEADDR: ' );
                    }
                }
                else {
                    $bix{ 'SESSION' . get_runid() }->param( '-accesscount', 1 );
                }
            }
        }

    }
}


sub _validate_user {
    my ( $username, $pass, $userFileName ) = @_;
    $BixChange::bix{ 'USESESSIONS' . get_runid() }++;

    if ( !$bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{USERCHECKS} ) {
        $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{USERCHECKS} = $userFileName
          || XINI->new( _OS_pathswitch('./data/u/us/users.ini') );
        $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{USERCHECKS}->rock();
        my $rolled = $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{USERCHECKS}->roll();
        my @userrecord = grep { $_->{NAME} eq $username } @{ $rolled->{USERS} };
        if (@userrecord) {
            if ( $userrecord[0]->{PASSWORD} eq
                crypt( $pass, $bix{'UNIVERSALSALT'} || 'UNIVERSALSALT' ) )
            {
                &initiate_session;
                return $bix{ 'SESSION' . BixChange::get_runid() };
            }
        }
        else {
            return undef;
        }
    }

}


sub _newcookie {
    my ($instref) = @_;
    my $c = new CGI::Cookie(%$instref);

    #    if (!$c->domain()){
    #	$c->domain($bix{DOMAIN});
    #    }
    if ($c) {
        push @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{COOKIEJAR} }, $c;
    }

}


sub _getcookies {
    my $cref = fetch CGI::Cookie;
    return $cref;

}


# _htendl (AUTOLOADED)

# _switch_tmpl (AUTOLOADED)

sub _untaint_param {
    my ( $paramname, $untaint ) = @_;
    my $cleanvalue;
    if (
        defined(
            $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CLEANVALUES}->{$paramname}
        )
      )
    {
        return (
            $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CLEANVALUES}->{$paramname} );
    }
    if ( param($paramname) && ( ( param($paramname) =~ m/($untaint)/ ) ) ) {
        $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CLEANVALUES}->{$paramname} = $1;
    }
    return ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{CLEANVALUES}->{$paramname} );
}


sub _filearchive {

    #assumes that the passed in value has been untainted
    #have to implement flock on this or a lock file
    my ( $archivename, $message ) = @_;
    $archivename = _OS_pathswitch(qq(./data/_archives/$archivename));
    open( HANDLE, qq(>>$archivename\.lock) ) or die $!;
    flock( HANDLE, LOCK_EX );
    open( HANDLE2, qq(>>$archivename\.dat) ) or die $!;
    print HANDLE2 $message;
    close(HANDLE2);
    flock( HANDLE, LOCK_UN );
    close(HANDLE);
    return "OK";
}


sub _semaphore_lock_on {

    #assumes that the passed in value has been untainted
    #have to implement flock on this or a lock file
    #This time you will have to pass in the entire path to the archive
    my ( $archivename, $message ) = @_;
    $archivename = _OS_pathswitch(qq($archivename));
    open( HANDLE, qq(>>$archivename\.lock) ) or die $!;
    flock( HANDLE, LOCK_EX );
    $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{SEMALOCK} = *HANDLE;
    return "OK";
}



sub _semaphore_lock_off {

    flock( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{SEMALOCK}, LOCK_UN );
    close( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{SEMALOCK} );
    return "OK"

}

# _publishtosubscribers (AUTOLOADED)  

# _poparchive (AUTOLOADED)


sub _force_values {
    my ($valuesref) = @_;
    push @{ $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{BANK} }, $valuesref;

}


sub _studder {
    my $file     = shift;
    my @patharr  = split //, $file;
    my $filepath = qq(./data/$patharr[0]/$patharr[0]$patharr[1]/$file.ini);
    return ( _OS_pathswitch($filepath) );
}

# _A_HREF (AUTOLOADED)

#  _html_ret (AUTOLOADED)

#  _get_universe_data (AUTOLOADED)

# _html_from_univ (AUTOLOADED)

# setlibs (AUTOLOADED)

sub get_runid {

    return ( $bix{'uniqRUN'} );

}

sub munge_runid {
    my ($tag) = @_;
    return ( $tag . get_runid() );
}


sub get_private {
    my ($name) = @_;
    my $runid = get_runid();
    return ( $bix{ 'PRIVATE' . $runid }->{$name} );

}

sub set_private {
    my ( $newname, $value ) = @_;

    $bix{ 'PRIVATE' . get_runid() }->{$newname} = $value;

}

sub persist {

    #if passed-in value is some kind of object,
    #we'll assume it is a DB handle...otherwise,
    #use some kind of DBM

    if (   ( $_[1] )
        or ( Scalar::Util::looks_like_number( $_[1] ) && ( $_[1] == 0 ) ) )
    {
        if ( $_[1] eq 'nix' ) {
            undef $bix{'PERSIST'}->{ $_[0] };
        }
        else {
            if ( ref( \$_[1] ) !~ m/SCALAR|HASH|ARRAY/ ) {
                $bix{'DBPERSIST'}->{ $_[0] } = $_[1];
            }
            else {
                $bix{'PERSIST'}->{ $_[0] } = $_[1];
            }
        }
    }
    else {
        return ( $bix{'PERSIST'}->{ $_[0] } || $bix{'DBPERSIST'}->{ $_[0] } );
    }
}

# persist_ref (AUTOLOADED)

# incr_persist (AUTOLOADED)

sub stop_break {
    warn "You forgot to remove stop_break from your code.\n";
}

sub last_breath {
    my $say = shift;
    print header;

    print "<HTML><BODY>Unrecoverable Error: $say</BODY></HTML>";

}

DESTROY {

#with p5httpd_win32 the PRIVATE section of %bix contains stuff that will be cached
#and rerun the next time around. In order to avoid this (if you want to use p5httpd_win32)
#put your 'destroyables' in the PRIVATE area
    qx/echo Bx: FIRING DESTROY >> $bix{BXTRACEFILE}/ if $bix{BXTRACE};
    open( LOG, ">>" . _OS_pathswitch("./log/logfiles.log") )
      or last_breath('Cannot open time stamp log file!');

    foreach ( @{ $bix{LOGCACHE} } ) {
        print LOG qq($_\n);
    }
    close(LOG);

    delete $bix{'LOGCACHE'};
    if ( $bix{'uniqRUN'} ) {
        delete $bix{ 'USER' . $bix{'uniqRUN'} };
        delete $bix{ 'custom_report_header' . $bix{'uniqRUN'} };
        if ( $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'USERCHECKS'} ) {
            delete $bix{ 'PRIVATE' . $bix{'uniqRUN'} }->{'USERCHECKS'};
        }
        delete $bix{ 'SESSION' . $bix{'uniqRUN'} };
        delete $bix{ 'USESESSIONS' . $bix{'uniqRUN'} };
        delete $bix{ 'custom_report_header' . $bix{'uniqRUN'} };
        delete( $bix{ 'PRIVATE' . $bix{'uniqRUN'} } );
        delete( $bix{'uniqRUN'} );

    }
    untie $SESSIONID;
    untie $PRIVATE;
    untie $USESESSIONS;
    untie $USER;
    untie $CUSTOM_REPORT_HEADER;

    delete $bix{'custom_report_header'};

}

END:

1;

__END__


=head1 NAME

BixChange: Package that maintains the methods needed to run BixChange

=head1 SYNOPSIS

  use BixChange;


=head1 DESCRIPTION

  Use this library to call BixChange methods.

=head2 EXPORT

None by default.

=head1 SEE ALSO

 HTML::Template

=head1 AUTHOR

Joel Limardo joel.limardo@forwardphase.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joel Limardo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
