package BixConfig;
require Exporter;
@ISA = qw/Exporter/;
use CGI qw/:standard/;

#The following is a bunch of variables that determine the configuration
#of the system. In order to keep you from flooding this with crap, we have
#adopted the convention of keeping config items in the bix hash. 
#That way we can say print keys %bix, etc. to find out what all of the
#config items are for the manager elsewhere. If you do decide to add
#your own variables then make sure that you export them or you will
#have to prepend them with BixConfig:: every time.

#YOUR_OWN_LIBRARIES is file which contains calls to your own libraries.
#It will be required at run-time, so make sure it works!

$BixChange::bix{'your_own_libraries'} = '.\\lib\\user_libs.pl';

#What is this systemname?
$BixChange::bix{'systemname'} = "bixchange.cgi";

#PAGE_TEMPLATE is the most important part of rendering pages in Bixchange.
#You will need to refer to the documentation if you are unfamiliar
#with HTML::Template

$BixChange::bix{'page_template'} = '.\\tmpl\\azure\\base.tmpl';

#HTML_DIE_ON_BAD_PARAMS keeps your system from dying if you accidentally
#mistype a variable name in your .ini file or you add a tag for future
#reference that you are not immediately going to use it. Only change
#this if you are in a very strict environment that MUST have a one to
#one match between your .ini files and your templates.

$BixChange::bix{'html_die_on_bad_params'} = 0;

#WHEREAMI is the path to the bixchange program. Be specific and use a URI.
#Do not use a slash at the end and change this from localhost if you are
#putting this on a server other than your local machine.

$BixChange::bix{'whereami'} = "http://localhost/perl/bixchange";

#WHEREAMIREALLY is the actual path to the directory above the script
$BixChange::bix{'whereamireally'} = '/srv/www/mod_perl/bixchange';


#DOMAIN is mostly used for cookies. Place the name of your domain here.
#If you do not know what a domain is then you probably do not need
#to use this setting either.

$BixChange::bix{DOMAIN} = '.localhost';

#DIE_ON_BAD_INI_EVALS will print the error message page when some eval
#statement in an ini file fails. Turn this on if you are certain that your
#eval statements are all in perfect working order

$BixChange::bix{'die_on_bad_ini_evals'} = 1; #1 == true

#REFRESH_SPEED is the number of seconds before a refresh of your page. Set this
#wisely

$BixChange::bix{'refresh_speed'} = 20; #default

#DIE_ON_BAD_FILTERS Sends the cgi_die page whenever a failure occurs on parsing a filter

$BixChange::bix{'die_on_bad_filters'} = 1; #1 == true

#CUSTOM_REPORT_HEADER allows you to override the normal HTML type report headers with one
#of your own. You should probably only change this in an eval statement.

$BixChange::bix{'custom_report_header'} = '';

#USESESSIONS is boolean (in the perl sense) where a true value means that a new session
#id will be created/retrieved in BixChange. Default setting is OFF

$BixChange::bix{USESESSIONS} = 0;


#UNIVERSALSALT is used when validating users. Change this.

$BixChange::bix{UNIVERSALSALT} = 'zmpx9870xju';

#KILLSESSIONAFTER determines the lifetime of a session. It is basically an access counter kept
#inside of a cgisession file/database entry. Change this to 'INFINITE' if you plan to write
#some kind of cron job that will clean out all of the session files yourself or you plan to
#use a database to maintain sessions.

$BixChange::bix{KILLSESSIONAFTER} = 15; #fifteen accesses.

#CGISESSIONDRIVER is the driver string used to create CGI::Sessions
$BixChange::bix{CGISESSIONDRIVER} = q(driver:File);

#CGISESSIONPATH is the Directory where CGI::Session files (if you are using
#the default file mode) are kept
$BixChange::bix{CGISESSIONPATH} = q(./data/_sessions);


#BXTRACE  Turn this on when you want a file full of trace data
$BixChange::bix{BXTRACE} = 0;

#BXTRACEFILE Specify the file you want trace lines to write to
$BixChange::bix{BXTRACEFILE} = 'bxtracefile.txt';

#BXHOMEDIRECTORY. Specify where bixchange was installed (w/out the ending slashes)
$BixChange::bix{BXHOMEDIRECTORY} = 'c:\p5httpd_win32\cgi-bin\bixchange';

#VERSION_NUMBER, the numeric version for this release
$BixChange::bix{VERSION_NUMBER} = 1.8;

#VERSION_PATCH, a letter designation indicating a patch (a,b,c...etc). So a
#real version name for a given release could be 1.8b.
$BixChange::bix{VERSION_PATCH} = q|c|;

#VERSION, combination of VERSION_NUMBER and VERSION_PATCH. Use as needed.
$BixChange::bix{'VERSION'} = $BixChange::bix{'VERSION_NUMBER'} . $BixChange::bix{'VERSION_PATCH'};

#FILEPATHMAP, a hash of extension=>paths
%{$BixChange::bix{'FILEPATHMAP'}} = ( 'tmpl'=>'/tmpl',
                           'ini'=>'<<<studder>>>' );

#DBMFORPERSIST is the DBM class to use for PERSIST
$BixChange::bix{'DBMFORPERSIST'} = "GDBM_File";

#IMAGES, path to images

$BixChange::bix{'IMAGES'} = 'http://fireflyii/images';

#HTMLSAFESYMBOLS
%{$BixChange::bix{'HTMLSAFESYMBOLS'}} =  (
    qq|\n|,qq|<BR />\n|,
    '$'=>'&#36;',
    '%'=>'&#37;',
    '&'=>'&#38;',
    q|'|=>'&#39;',
    q|`|=>'&#96;',
    '('=>'&#40;',
    ')'=>'&#41;',
    '*',=>'&#42;',
    '?'=>'&#63;',
    '@'=>'&#64;',
    ']'=>'&#93;',
    '['=>'&#91;',
    '_'=>'&#95;',
    '^'=>'&#94;',
    '{'=>'&#123;',
    '}'=>'&#125;',
    '|'=>'&#124;',
    '~'=>'&#126;'
    );

#===============subs===============

sub RunValue {
    my (@vars) = @_;
    my $uniqRun = BixChange::get_runid();

    if ($vars[1]){
         $BixChange::bix{$vars[0] . $uniqRun} = $vars[1];   
     }
    return( $BixChange::bix{$vars[0] . $uniqRun});
}
#=======================================
#=== subs for tied variables ===========

sub TIESCALAR {
    my ($class, $name) = @_;
    return bless \$name, $class;
}

sub FETCH {
    my $self = shift;
    my $runid = BixChange::get_runid();
    #my $thing = $$self . BixChange::get_runid();
    if (($$self eq 'SESSIONID')&&($BixChange::bix{'SESSION' . $runid}))
    {
      return ($BixChange::bix{'SESSION' . BixChange::get_runid()}->id());
    }
    else
    {
      return ($BixChange::bix{$$self . BixChange::get_runid()});
    }


}

sub STORE {
    my ($self, $val) = @_;
    $BixChange::bix{$$self . BixChange::get_runid()} = $val;
}


1;
