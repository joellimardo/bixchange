#!/usr/bin/perl -w

use Data::Dumper;
use lib qw|. ./lib ./lib/cpan ./lib/auto|;

use BixChange;

if (BixChange::_OS_pathswitch('/') eq '/'){
      use lib qw(. ./lib ./lib/cpan);
  } else {
      use lib qw(. .\lib .\lib\cpan);
  }

use strict;
use Cwd qw/getcwd/;
use HTML::Template;
use Getopt::Long;

my ($template, $helpflag, $recompile, $harbormigrate, $filter_file_name, $filtername, $runfilter, $file, $renumber, $dissect, $reversion, $indexItAll, $pwd,$scanfile, $pomname, $piefl);
if (@ARGV){
 GetOptions('analyze_tmpl=s'=>\$template, 
            'help'=>\$helpflag, 
            'harbor_migrate'=>\$harbormigrate,
            'recompile'=>\$recompile,
            'filter_file_name=s'=>\$filter_file_name,
            'filtername=s'=>\$filtername,
            'runfilter'=>\$runfilter,
            'renumber'=>\$renumber,
            'file=s'=>\$file, 
            'dissect=s'=>\$dissect,
            'reversion'=>\$reversion,
            'index'=>\$indexItAll,
            'password=s'=>\$pwd,
            'kitscan=s'=>\$scanfile,
            'dbmlinks=s'=>\$pomname,
            'piefl=s'=>\$piefl
            );
}

die &usage if ($helpflag);

if (defined($template)) {print analyze_tmpl($template)};
if (defined($recompile)) {&re_compile_site};
if (defined($harbormigrate)) {&move_from_harbor};
if (defined($runfilter)) {&filtertester};
if (defined($renumber) && defined($file)) {renumber($file)};
if (defined($dissect)) {dissect_file($dissect)};
if (defined($reversion)) {&reversion};
if (defined($indexItAll)) {&indexItAll};
if (defined($pwd)){encrypt($pwd)};
if (defined($scanfile)){kitscan($scanfile)};
if (defined($pomname)){pomlinks2dbm($pomname)};
if (defined($piefl)) {piefl($piefl)};
#-------------------------------------------------------------
#                            Subs
#-------------------------------------------------------------

sub re_compile_site {
 my $Verbose = '$Verbose';
 my @files;
 chdir ('./lib/cpan') or cgi_die ('Cannot switch to cpan directory!');  
 use lib qw|.|;

@files = glob('../*.end');

 my $result = 'USER LIBS: ';
 eval('use AutoSplit qw|$Verbose autosplit|');
 if ($@){
     die $@;
 } else {

     foreach my $fl (@files)
     { 
       $result .= autosplit($fl,'../../lib/auto',1,0,0);
      }
     $result .= qq(\nCORE LIBS: );
     $result .= autosplit('../../bixchange.cgi', '../auto', 1, 1, 0);
 }

 print $result;
}

sub analyze_tmpl{
  my $filename= shift;
  my $tmpl = HTML::Template->new(filename=>$filename);
  print join "\n", ($tmpl->param());
 }
 
 sub move_from_harbor {
 
  my $correct_slash=BixChange::_OS_pathswitch("/");
  if ($correct_slash eq '\\') {$correct_slash = '\\\\'};
  my @files = map {(split/$correct_slash/,$_)[-1]} glob(q(.\data\harbor\*.ini));
  foreach(@files) {
   my @name = split//;
   my $topdir = $name[0];
   my $filepath = BixChange::_OS_pathswitch(qq(./data/$name[0]/$name[0]$name[1]));
   my $subdir = $name[0] . $name[1];
   my $filename = BixChange::_OS_pathswitch(qq($filepath/$_));
   
   my $filecontents = '';
   if (!(-d BixChange::_OS_pathswitch(qq|./data/$topdir|))) 
   {   chdir (qq|./data|) or die $!;
       mkdir $topdir or die $!;
       chdir (q|..|) or die $!;
   }
   if (!(-d BixChange::_OS_pathswitch(qq|./data/$topdir/$subdir|))) 
   {
       chdir ( BixChange::_OS_pathswitch(qq|./data/$topdir|) ) or die "Cannot access directory for $filename!";
       mkdir (  $subdir ) or die $!;
       for(1..2) {chdir (qq|..|) or die $!;}
       
   }
   
     my $line;
     #harborfile is tainted
     my $harborfile =BixChange::_OS_pathswitch(qq(./data/harbor/$_)); 
     if($harborfile=~m/^([^\\\/]+\S+\.ini)/) { $harborfile = $1};
    open(READHANDLE, $harborfile ) or BixChange::cgi_die("Cannot open $_");
       while($line = <READHANDLE>) {
         $filecontents .= $line;
       };
    close(READHANDLE);
    #filename is tainted
    if ($filename=~m/^([^\\\/]+\S+\.ini)/) { $filename = $1}; 
    if (!-f $filename)
    {
        open(WRITEHANDLE,BixChange::_OS_pathswitch(">$filename")) or BixChange::cgi_die("Cannot write to $filename");
        print WRITEHANDLE $filecontents;
        close(WRITEHANDLE);
        print qq|Wrote $filename to central playground!\n|;
        $filecontents = '';
        unlink $harborfile;
    }
    else
    {
	print "Error: $filename already exists in playground...rename, remove, or merge the files.\n";
    }
    
  }
  
 }
 
 sub renumber {
 
   my ($file) = @_;
   if (!-f $file) {cgi_die('Cannot open ' . $file)};
   open (HANDLE,"$file")|| die("Cannot open $file!");
     my @lines = <HANDLE>;
   close(HANDLE);
   my $anum = 0;
   my $lastsect = '';
   my @bucket;
   for my $line (@lines) {
    if ($line=~m/^\[LOOP\s+(\S+?)(\d+|\sx(\.x)*|\d+(?:\.\d+)*)\s*\]/) {
       if ($1 ne $lastsect ) {$anum = 1} else {$anum = incr_special($anum,$2)};
       $lastsect = $1;
       $line=~s/^\[LOOP\s+(\S+?)(\d+|\sx(\.x)*|\d+(?:\.\d+)*)\s*\]/\[LOOP $1$anum\]/;    
                   
     }
    push @bucket, $line;      
   }
   
      
   print @bucket;
=head1 TODO


=head2 CHANGES NEEDED
 
Make this work with -p -i.bak -e

=cut
 
 }
 
 sub incr_special {
     my ($item, $syntax) = @_;
     my @a = split /\./,$item;
     my @b = split /\./,$syntax;
     my @newrep = map {(shift @a)||0} @b;
     $newrep[-1]++;
     my $rtval = join('.',@newrep);
     if (index($rtval,'.0') > -1) {
 	return "ERROR: Cannot derive $item from $syntax!\n";
     }else {
 	return $rtval;
     }
}

sub dissect_file {
    my ($filename) = @_;
    chdir('./lib') or die $!;
    my $runstr = 'perl -MData::Dumper -e "$ENV{REQD} = 1;require qq(../bixchange.cgi); use XINI; my $rev1=XINI->new(qq( ' . $filename . ')); $rev1->rock(); print Dumper $rev1->roll();';
    my $result = `$runstr`;
    print $result;

}

sub reversion {
    my $instr = qq(echo 'foo' > version.txt);
   # my $instr = q~perl -e "print q|$Id: utils.pl,v 1.3 2009/06/13 16:08:24 joellimardo Exp $|; foreach $dir qw!* ./lib/*.pm! {print map {(stat $_)[9]} glob($dir)};" > version.txt~;
    `$instr`;
}

sub indexItAll {

 use Config::IniFiles; 
 use File::Find; 
 $main::zimNumber = 0;
 $main::ManagerNumber = 0;
 $main::blintz = qq|[GENERAL]\nPAGETYPE=FORM\nDEFAULTTEMPLATE=./tmpl/indx.tmpl\n\n|; 
$main::blintz .= qq|[TEMPLATE ZIMS]\nDESCRIPTION=\nLINK=\nNAME=\nKEYWORDS=\n\n|;
 find({no_chdir=>1, wanted=>\&wanted_items}, './data/'); 
 find({no_chdir=>1, wanted=>\&wanted_managers}, './data/');
 print $main::blintz;

 }

sub wanted_items 
 {
   if (/\.ini$/ )
    { my $fname=$_; 
      $fname=~s/\//\\/g; 
      my $fl = new Config::IniFiles(-file=>qq|$fname|); 
      if ($fl && ($fl->val('GENERAL','META-DESCRIPTION'))) {$main::zimNumber++; $main::blintz .= qq|\n\n[LOOP ZIMS| . $main::zimNumber . qq|]\n| . 'DESCRIPTION=' . $fl->val('GENERAL','META-DESCRIPTION') . qq|\nLINK=| . $fl->val('GENERAL','META-STARTLINK') . qq|\nNAME=| . $fl->val('GENERAL','META-NAME')  . qq|\nKEYWORDS=| . $fl->val('GENERAL','META-KEYWORDS')};
  }
}

sub wanted_managers 
 {
   if (/\.ini$/ )
    { my $fname=$_; 
      $fname=~s/\//\\/g; 
      my $fl = new Config::IniFiles(-file=>qq|$fname|); 
      if ($fl && ($fl->val('GENERAL','META-MANAGER'))) {$main::ManagerNumber++; $main::blintz .= qq|\n\n[LOOP MANAGEMENT| . $main::ManagerNumber . qq|]\n| . 'DESCRIPTION=' . $fl->val('GENERAL','META-MANAGERDESCRIPTION') . qq|\nLINK=| . $fl->val('GENERAL','META-MANAGERSTARTLINK') . qq|\nNAME=| . $fl->val('GENERAL','META-MANAGERNAME')};
  }
}

sub encrypt {
  my ($pwd) = @_;
  use BixConfig;
  print crypt($pwd, $bix{'UNIVERSALSALT'});   
 
}

sub kitscan {

    my ($tarname) = shift @_;

    if (!-f $tarname){
	print "Unable to find file! $tarname\n";
        die;
    }
    use Archive::Tar;
    my $obj = Archive::Tar->new();
    my $output = Archive::Tar->new();
    $obj->read($tarname,1);
    unlink('currentbackup.tar');
    foreach my $file ($obj->list_files()){
	#$file=~s/\//\\/g;
        if (-e $file){
	    #print `tar -vf currentbackup.tar --append \"$file\"`;
            $output->add_files($file);
        }
    }
    $output->write('currentbackup.tar');
   # system('tar -cvf currentbackup.tar -T anticollision.dat');
   # system('tar -vf currentbackup.tar --list');
}

sub pomlinks2dbm {
  
    use XPOM;
    my $pomObj = new XPOM($pomname);
    $pomObj->dbmlinks();

}

sub usage {
    print <<EOF;

USAGE: perl -utils.pl <options>

options:

    --analyze_tmpl=<template>   Experimental
    --help                      Displays this message
    --harbor_migrate            Moves INI files from the harbor
    --recompile                 Autosplits .end files
    --filter_file_name=<filter> Experimental
    --filtername                Experimental
    --runfilter                 Experimental
    --renumber                  
       --file                   Renumbers the LOOP sections in the file
    --dissect                   Experimental
    --reversion=<file>          Experimental
    --index                     Scans files for META tags to STDOUT
    --password=<password>       Creates a new password with UNIVERSALSALT
    --kitscan=<file>            Scans for resources in .tar with same 
                                name and archives them
    --dbmlinks=<pomname>        Creates a new DBM or updates with links from POM
    --piefl=<name>              Create a prototypical .DAT file w/directories
EOF


}

sub piefl {

    my ($new_package_name) = @_;

    print qq|=======| . getcwd() . qq|==================\n|;

     die 'Usage: perl utils.pl --piefl=PACKAGENAME' unless ($new_package_name) ;

     chdir 'packages' or die 'Packages directory is missing -- bad install';

     dirmk($new_package_name,0755);
     chdir $new_package_name or die $!;

     dirmk('tmpl',0755);
     dirmk('DOCS',0755);
     dirmk(qq~DOCS/$new_package_name~, 0755);
     dirmk('data',0755);
     dirmk('data/' . substr($new_package_name, 0,1), 0755);
     dirmk('data/' . substr($new_package_name, 0,1) . '/' . substr($new_package_name, 0,2),  0755);

     dirmk('test',0755);

     chdir '..' or die $!;
     mktrainres($new_package_name);
     mkpom($new_package_name);

}

###### Util functions #######

########################################
sub dirmk {
########################################

    my ($dir, $perms) = @_;
    mkdir $dir or die $!;
    chmod $perms, $dir or die $!;
}
########################################
sub mktrainres {
########################################
    my ($package_name) = @_;
    my $homefile = "$package_name/data/" . 
                   substr($package_name,0,1) . '/' . 
                   substr($package_name,0,2) . '/' .
                   $package_name . 'train.ini';
    open (my $fh, '>', $homefile ) or die qq|Error with $homefile: $!|;
    print $fh <<EOF;
[GENERAL]
TRAIN=true
EOF
    close($fh) or die $!; 
}

########################################
sub mkdummytmpl {
########################################
    my ($package_name) = @_;
}

########################################
sub mkpom {
########################################
    my ($package_name) = @_;
    my $pomfile = "$package_name/DOCS/$package_name/" . 
                   $package_name . '-pom.xml';
    open (my $fh, '>', $pomfile ) or die qq|Error with $pomfile: $!|;
    print $fh <<EOF;
<xml>

</xml>
EOF
    close($fh) or die $!; 
       
}

END:

1;



