package SENDMAILER;

# $Id: SENDMAILER.pm,v 1.1 2007/07/20 03:24:42 joellimardo Exp $

BEGIN{
$VERSION = 1.0;	
use Exporter();
@ISA = qw/Exporter/;
@EXPORT = qw/&send_the_mail/;
}
use strict;

sub new {
  my $self = {};
  bless $self;
  return $self;
}

sub send_the_mail {

my ($class, $from, $subject, $message, $recipientList) = @_;

if (!(ref($from) eq 'HASH'))
{
   $from = $class;  
} 

   
 my ($fromref) = $from;
 $from = $fromref->{'FROM'};
 $message = $fromref->{'MESSAGE'};
 $subject = $fromref->{'SUBJECT'};
 $recipientList = $fromref->{'RECIPIENTLIST'};
    

my ($mailprog);
$mailprog = '/usr/sbin/sendmail -t';

open(MAIL,"| $mailprog") or die 'cannot open sendmail!';
print MAIL 'From: ' . $from . "\n"; 
print MAIL "To: $recipientList" , "\n";
print MAIL 'Subject: ' , "$subject\n\n";
print MAIL "$message";
close(MAIL);

}
1;

=head1 PURPOSE

This simply mails out the (subject, message, etc.) parameters passed into the function to
the recipientlist using sendmail.

=head1 SYNOPSIS

    use SENDMAILER;
    send_the_mail({FROM=>'niceguy\@hell.com',SUBJECT=>'Get off my back!', MESSAGE=>'where is my money?',RECIPIENTLIST=>'creditor\@japan.com');
=head1 DESCRIPTION

This module is extremely basic. Feel free to modify/replace it.

=cut
