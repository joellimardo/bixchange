#!/usr/bin/perl -w
use strict;
use Tk;
use Tk::widgets qw|JPEG PNG|;
use Cwd qw|getcwd|;
use File::Find;
#$Id: dumona.pl,v 1.2 2010/09/21 01:17:25 joellimardo Exp $
our $VERSION = '0.7';

use XML::Simple;
use DU;

package Dumona;

sub new {
    
    my ($self) = {};
    foreach( qw|'MAINMENU'
    'SECONDMENU'
    'COMMBUTTON'
    'CHECKBUTTON' 
    'THIRDBUTTON' 
    'WORLDBUTTON'
    'THIRDMENU'
    'MENUPLUGINS'
    'BODYFRAME'
    'MENUBAR'
    'ICONBAR'
    'MAINWINDOW'
    'ROOTDIR'
    'BODY'
    'OUTPUTBODY'
    'BODYVALUE'
    'LISTBOXES'
    'LBOXSCROLL1'
    'LBOXSCROLL2'
    'STATUSBAR'
    'BOTTOMSTATS' 
    'CONTROLGROUP'
    'ONELINEGROUP'
    'OUTPUTGROUP'
    'CONTROL1VAR'
    'CONTROL2VAR'
    'ONELINETEXT'
    'OUTPUTGROUPVAR'
    'STATUSTEXT'|)
    { $self->{$_} = 1};
    $self->{'ALLINIS'} = []; #holds all of the resource file names under the ROOTDIR
    bless $self;
    return $self;
}

package main;

local ($/);

my $data = <DATA>;
my $xml = XMLin($data);
my $duObj = Dumona->new();
$duObj->{'STATUSTEXT'} = "Greetings";
#   main form
my $mw = Tk::MainWindow->new();

my $icon = $mw->Photo(-file=>'./images/monster3.gif');
my $othericon = $mw->Photo(-file=>'./images/fakelogo1.gifbutton1.gif');
my $thirdicon = $mw->Photo(-file=>'./images/yy.png');
my $worldicon = $mw->Photo(-file=>'./images/world.jpg');


$mw->iconimage($icon);
#$mw->minsize(700,400);
   
$duObj->{'MENUBAR'} = $mw->Frame(-relief=>'raised')
                     ->pack(-side=>'top', -fill=>'x');
$duObj->{'ICONBAR'} = $mw->Frame(-relief=>'sunken')
                     ->pack(-side=>'top', -fill=>'x');

$duObj->{'CONTROLGROUP'} = $mw->Frame()->pack(-fill=>'x');

$duObj->{'CONTROLGROUP'}->Optionmenu(
                          -options=>packages(),
                          -command=>sub{ print "got: " , shift, "\n"},
                          -width=>12,
                          -variable=>$duObj->{'CONTROL1VAR'})->pack(-side=>'left');

$duObj->{'CONTROLGROUP'}->Optionmenu(
                          -options=>[[once=>1],[doce=>2],[thres=>3]],
                          -command=>sub{ print "got: " , shift, "\n"},
                          -width=>12,
                          -variable=>$duObj->{'CONTROL2VAR'})->pack(-side=>'left');

$duObj->{'COMMBUTTON'} = $duObj->{'ICONBAR'}->Button(-text=>'Enlarge', 
                                                     -image=>$icon)
                                            ->pack(-side=>'left');

$duObj->{'CHECKBUTTON'} = $duObj->{'ICONBAR'}->Button(-text=>'Fake',
                                                      -image=>$othericon)
                                             ->pack(-side=>'left');

$duObj->{'THIRDBUTTON'} = $duObj->{'ICONBAR'}->Button(-text=>'Fake2',
                                                      -image=>$thirdicon)
                                             ->pack(-side=>'left');


$duObj->{'WORLDBUTTON'} = $duObj->{'ICONBAR'}->Button(-text=>'Fake2',
                                                      -image=>$worldicon)
                                             ->pack(-side=>'left');

$duObj->{'BODYFRAME'} = $mw->Frame(-relief=>'sunken')
                                            ->pack(-side=>'top',
                                                   -fill=>'x');

$duObj->{'ONELINEGROUP'} = $mw->Frame()->pack(-fill=>'x');
$duObj->{'ONELINEGROUP'}->Button(-text=>'Execute')->pack(-side=>'left');
$duObj->{'ONELINETEXT'} =
    $duObj->{'ONELINEGROUP'}->Entry(-width=>120)->pack(-side=>'left');

$duObj->{'OUTPUTGROUP'} = $mw->Frame()->pack(-fill=>'x');
$duObj->{'OUTPUTBODY'} = 
          $duObj->{'OUTPUTGROUP'}->Scrolled("Text",-width=>75,-height=>10,-wrap=>'none',-scrollbars=>'se')->pack(-expand=>1,-fill=>'both');

$duObj->{'BOTTOMSTATS'} = $mw->Frame(-relief=>'raised')->pack(-fill=>'x');

  
$duObj->{'MAINMENU'} = $duObj->{'MENUBAR'}->Menubutton(-text=>'File' ,
                                                       -underline=>0 ,
                                                       -tearoff=>0)
                                            ->pack(-side=>'left');

$duObj->{'MAINMENU'}->command(-label=>'Login', -command=>\&call_login_window);
$duObj->{'MAINMENU'}->command(-label=>'ChDir', -command=>\&call_rootdir_window);
$duObj->{'MAINMENU'}->command(-label=>'Exit',  -command=>sub {exit}); 

$duObj->{'SECONDMENU'}= $duObj->{'MENUBAR'}->Menubutton(-text=>'Tools', 
                                                        -underline=>1 ,
                                                        -tearoff=>0)
                                           ->pack(-side=>'left');

$duObj->{'SECONDMENU'}->command(-label=>'Font', 
                                -command=>\&confirm_stuff);      

$duObj->{'THIRDMENU'} = $duObj->{'MENUBAR'}->Menubutton(-text=>'JDS', 
                                                        -underline=>0,
                                                        -tearoff=>0)
                                           ->pack(-side=>'left');

$duObj->{'THIRDMENU'}->command(-label=>'Promote', -command=>\&jds_promote);

$duObj->{'4MENU'} = $duObj->{'MENUBAR'}->Menubutton(-text=>'POM', 
                                                    -underline=>0,
                                                    -tearoff=>0)
                                           ->pack(-side=>'left');

$duObj->{'4MENU'}->command(-label=>'Promote', -command=>\&jds_promote);

#single listbox on the left side for ini file names

my %listboxes = ('1'=>'',
                 '2'=>'',
                 '3'=>'',
                 '4'=>'',
                 '5'=>'');

$duObj->{'LISTBOXES'} = \%listboxes;

$duObj->{'LBOXSCROLL1'} = $duObj->{'BODYFRAME'}->Scrollbar();

$listboxes{'1'} = $duObj->{'BODYFRAME'}->Listbox(-selectmode=>1, -width=>retWidth('1'), -selectborderwidth=>4, -yscrollcommand=>['set'=>$duObj->{'LBOXSCROLL1'}]);
$duObj->{'LBOXSCROLL1'}->configure(-command=>['yview'=>$listboxes{'1'}]);
$listboxes{'1'}->pack(-side=>'left', -fill=>'y');
$duObj->{'LBOXSCROLL1'}->pack(-side=>'left',-fill=>'y');


#same setup

$duObj->{'LBOXSCROLL2'} = $duObj->{'BODYFRAME'}->Scrollbar();

 $listboxes{'2'} = $duObj->{'BODYFRAME'}->Listbox(-selectmode=>1, -width=>retWidth('1'), -yscrollcommand=>['set'=>$duObj->{'LBOXSCROLL2'}]);
$duObj->{'LBOXSCROLL2'}->configure(-command=>['yview'=>$listboxes{'2'}]);

$listboxes{'2'}->bind('<Button-1>', sub { lbscreech ($listboxes{'2'},$duObj)} );
$listboxes{'2'}->pack(-side=>'left', -fill=>'both');
$duObj->{'LBOXSCROLL2'}->pack(-side=>'left',-fill=>'y');

$duObj->{'BODY'} = $duObj->{'BODYFRAME'}->Scrolled("Text",-width=>75,-wrap=>'none', -scrollbars=>'se')->pack(-expand=>1, -fill=>'both');

$duObj->{'STATUSBAR'} = $duObj->{'BOTTOMSTATS'}
                              ->Label(-textvariable=>\$duObj->{'STATUSTEXT'}, -relief=>'groove' )->pack(-side=>'left', -fill=>'x');

# Main Loop

MainLoop;

# -----------------------------------------------
#                  CALLBACKS
# -----------------------------------------------
sub call_login_window {
  my $entry_val;
  my $login_mw = Tk::MainWindow->new();
	 $login_mw->title("Login screen");
	 $login_mw->minsize(200,100);
	 $login_mw->Entry(-textvariable=>\$entry_val, -show=>'*', -takefocus=>1)->pack();
	 $login_mw->Button(-text=>"Done" , -command=> sub {validate_user($entry_val,$login_mw)})->pack(-side=>"bottom");
}

#-----------------------------------------------
sub call_rootdir_window {
  my $entry_val;
  $entry_val = getcwd();
  $entry_val =~s/bin$//;
  my $login_mw = Tk::MainWindow->new();
  $login_mw->focusForce();
	 $login_mw->title("Root Directory?");
	 $login_mw->minsize(200,100);
	 $login_mw->Entry(-textvariable=>\$entry_val, -takefocus=>1)->pack();
	 $login_mw->Button(-text=>"Done" , -command=> sub {verify_directory($entry_val,$login_mw)})->pack(-side=>"bottom");
}
#----------------------------------------------
sub validate_user {
  my ($res, $sub_window) = @_;
  eval q|use SOAP::Lite|;
  if ($@)
  {
     print qq|Cannot run this operation. SOAP::Lite is not installed!|;    
  }
  else
  {
      eval q|use Mime::Tools|;
      if ($@)
      {
          print qq|Mime::Tools is not installed. Parsing SOAP will fail.|;
      }
      else
      {
          my $soap = SOAP::Lite->uri($res)->proxy($res . q|/soap-connector.cgi|);
          my $result = $soap->hello_you();

          unless ($result->fault)
          {
	      print $result->result;
	  }
          else
          {
             print qq|ERROR OCCURRED\n|;
             print join q|, |, $result->faultcode, qq|\n| . $result->faultstring;            
          }
      }
  }
  print $res;
  $sub_window->destroy();
}
#----------------------------------------------
sub verify_directory {
    my ($rdir, $sub_window) = @_;
    if (-d $rdir)
    {
	$duObj->{'ROOTDIR'} = $rdir;
        &setup_listboxes;

    }
    else
    {
       show_dialog("Error", "The path is formatted wrong!\n"); 
    }
    $sub_window->destroy();

}
#----------------------------------------------
sub show_dialog {
    my ($title,$msg) = @_;
    my $dlog = Tk::MainWindow->new();
    $dlog->focusForce();
	 $dlog->title($title||"Root Directory?");
	 $dlog->minsize(200,100);
         $dlog->Label( 
                  -takefocus=>1,
                  -anchor=>'w',
                  -justify=>'left',
                  -text=>$msg
		)->pack;
	 $dlog->Button(-text=>"Done" , -command=> sub {$dlog->destroy()})->pack(-side=>"bottom");


}
# -----------------------------------------------
#             SUPPORTING FUNCTIONS
# -----------------------------------------------

sub packages
{
    my $packages = [];
    my @sdirs = ();

    finddepth(sub{my $dirs = $File::Find::name; $dirs=~s/\\/\//g; if(-d $dirs){if($dirs=~m/([^\/]+)$/){push @$packages,[qq|$1|,1]}}},q|..\\packages\\|);

#    push @$packages,[q|ROADSTER|,1];

  
    return($packages);
}

#------------------------------------------------

sub retWidth {
  my $regwidth=15;
  my $num = shift;
  $num++;
  SWITCH: for($num) {
    m/1/ && return($regwidth);
    m/2/ && return($regwidth);
    m/3/ && return($regwidth);
    m/4/ && return(5);
    m/5/ && return($regwidth);
    }
    return(20); #default
}
#------------------------------------
sub confirm_stuff {
    my $du = new DU; 
    $du->createForm('flex.inc');
 
}

#------------------------------------
sub setup_listboxes {
    if (-d qq|$duObj->{'ROOTDIR'}\\data|) {
       #setup listbox 1 with packages and 2 with ini files
       #highlight any ini files that correspond with the current package
       #default to the first package in the list 
	my @files; 
        my @inis;
	#find(sub {if(/\.dat$/) { push @files,$_}},qq|$duObj->{'ROOTDIR'}|);
        @files = qw|POM INIS XOBJECT TEMPLATE TEST END LOG|;
  	     #$duObj->{'LISTBOXES'}->{'1'}->insert('end','ALL');
	     foreach(sort @files){
		 $duObj->{'LISTBOXES'}->{'1'}->insert('end',$_);
             }
        finddepth(sub{if(/\.ini$/){push @inis,$_}},qq|$duObj->{'ROOTDIR'}\\data|);
	     push @{$duObj->{'ALLINIS'}}, @inis;
	     foreach(sort @inis){
                  $duObj->{'LISTBOXES'}->{'2'}->insert('end',$_);
 	     }
    }
}

#-------------------------------
sub jds_promote {

    print 'promoting';


}

sub lbscreech {
    my ($e, $duObj) = @_;
    #show_dialog('Screech',$e->get($e->curselection()));   
    $duObj->{'BODY'}->delete("1.0","end");
    my $filename = $e->get($e->curselection());
    $duObj->{'BODY'}->insert('end',retFile($duObj->{'ROOTDIR'}, $filename));
    $duObj->{'STATUSTEXT'} = $filename;
}

sub retFile {
    my ($rootdir, $filename) = @_;
    my $filepath = $rootdir . '/data/' . substr($filename,0,1) . q|/|;
    $filepath .= substr($filename,0,2) . qq|/$filename|;
   if (-f $filepath) {
       open(H,qq|$filepath|) or die $!;
       local $/;
       my $str =  <H>;
       close(H);
       return ($str);
   } else {
       return "Cannot find file: $filepath!\n";
   }  
    
}

1;

__DATA__
<?xml version="1.0" ?>
<third-party-request>
   <product name="ABC" version="1">
   </product>
   <analysis replicate="1" version="1" name="DIFFUSION">
       <component name="comp1" type="N" min="-1" max="-1" pql_min="-1" pql_max="-1" product="ABC" />
   </analysis>
</third-party-request>   
