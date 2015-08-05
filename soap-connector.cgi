#!c:\perl\bin\perl.exe -w
use strict;

#$Id: soap-connector.cgi,v 1.2 2010/08/01 06:05:05 joellimardo Exp $

#print "Content-type: application/soap\n";
#print "Content-type: text/xml\n\n";

     use SOAP::Transport::HTTP;
     SOAP::Transport::HTTP::CGI->dispatch_to('BxSoap')->handle;
 
# print "------ hello ----- \n";

#---------------------------------------------------------------

package BxSoap;

sub hello_you {

  return "Hello you from BxSoap::hello_you on Apache 1!";
}

#----------------------------------------------------------
#
# ALL_PACKAGES - returns an array of .dat files in the 
# /bixchange dir
#----------------------------------------------------------
sub all_packages {

    my @files = glob('*.tar');
    return join('|', @files);
}

1;
