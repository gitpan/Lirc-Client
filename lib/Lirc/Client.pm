package Lirc::Client;

###########################################################################
# Lirc::Client
# Mark V. Grimes
# $Id: Client.pm,v 1.9 2003/06/27 17:16:04 mgrimes Exp $
#
# Package to interact with the LIRC deamon
# Copyright (c) 2001 Mark V. Grimes (mgrimes AT alumni DOT duke DOT edu).
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself. 
#
# Formatted with tabstops at 2
#
# Parts of this package were inspired by 
#  hotornot.pl by michael@engsoc.org, and
#  Perl LIRC Client (plircc) by Matti Airas (mairas@iki.fi)
# Thanks!
#
###########################################################################

use strict;
use IO::Socket;

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

# -------------------------------------------------------------------------------
# LircClient->new( <program>, [<lircrc-file>], [<lircd-device>], [<debug-flag>] );
#

sub new {
  my $self      = {};
  my $class     = shift;
  my $prog      = shift;
  my $lircrc    = shift || "$ENV{HOME}/.lircrc";
  my $dname      = shift || '/dev/lircd';
  my $debug      = shift || 0;
  
  bless $self;
  $self->initialize($prog, $lircrc, $dname, $debug) or die "LircdClient couldn't initialize device $dname: $!";
  return $self;
}

# -------------------------------------------------------------------------------

sub initialize {
  my $self = shift;
  my ($prog, $lircrc, $dname, $debug) = @_;
  
  $self->{sock}    = IO::Socket->new(Domain => &AF_UNIX,
                                    Type    => SOCK_STREAM,
                                    Peer    => $dname ) or die "couldn't connect to $dname: $!";
  $self->{prog}    = $prog;
  $self->{rcfile} = $lircrc;
  $self->{mode}    = '';
  $self->{debug}  = $debug;
  
  $self->parse_lircrc();

  return 1;
}

# -------------------------------------------------------------------------------

sub clean_up {
  my $self = shift;
  
  close $self->{sock};
}

# -------------------------------------------------------------------------------

sub parse_lircrc {
  my $self = shift;
  
  local(*RCFILE);
  open( RC_FILE, "<".$self->{rcfile} ) or die "couldn't open lircrc file ($self->{rcfile}): $!";

  my $in_block = 0;
  my $cur_mode = '';
  my %commands;

  my ($prog, $remote, $button, $repeat, $config, $mode, $flags);
  while(<RC_FILE>){
    s/^\s*#.*$//g;                            # remove commented lines

    print "> ($cur_mode) $_" if $self->{debug};
    
    if     (  /^\s*begin\s*$/i            ){  # begin block
      $in_block and die "Found begin inside a block in line: $_\n";
      $in_block = 1;
    
    } elsif(  /^\s*end\s*(\w*)\s*$/i          ){  # end block
      if( $1 ){
        if( $cur_mode eq $1 ){ $cur_mode = ''; next; }
        else { die "end \"$1\": found without associated begin mode"; }
      }
      
      $in_block or die "Found end outside of a block in line: $_\n";
      $in_block = 0;
      defined $prog or die "end of block found without a prog code at line: $_\n";
      next if( $prog ne $self->{prog} );
      $commands{"$remote-$button-$cur_mode"} = { conf => $config, rep => $repeat, mode => $mode, flag => $flags };
      ($prog, $remote, $button, $repeat, $config, $mode, $flags) = (undef, undef, undef, undef, undef, undef, undef, undef );  
    
    } elsif( /^\s*begin\s*(\w+)\s*$/i      ){  # begin mode block
      die "found embedded mode line: $_\n" if $cur_mode;
      die "begin mode found inside command block: $_\n" if $in_block;
      $cur_mode = $1;
    
    } elsif(  /^\s*(\w+)\s*=\s*(.*?)\s*$/  ){  # command
      my ($tok, $act) = ($1, $2);
      if   ($tok =~ /^prog$/i)  { $prog    = $act; }
      elsif($tok =~ /^remote$/i){  $remote  = $act; } 
      elsif($tok =~ /^button$/i){  $button  = $act; } 
      elsif($tok =~ /^repeat$/i){  $repeat  = $act; } 
      elsif($tok =~ /^config$/i){  $config  = $act; } 
      elsif($tok =~ /^mode$/i)  {  $mode    = $act; } 
      elsif($tok =~ /^flags$/i)  {  $flags  = $act; } 
    
    } elsif(  /^\s*$/                     ){  # blank line
      # do nothing
    } else {                                  # unrecognized
      die "Couldn't parse lircrc file ($self->{rcfile}) error in line: $_\n";
    }
  }
  close RC_FILE;
  $self->{commands} = \%commands;
}

# -------------------------------------------------------------------------------

sub recognized_commands {
  my $self = shift;
  
  my %commands = %{$self->{commands}};
  my @list;
  foreach my $c (keys %commands){
    push @list, "$c:\n  ";
    my %conf = %{$commands{$c}};
    foreach my $i (keys %conf){
      my $a = defined $conf{$i} ? $conf{$i} : 'undef';
      push @list, "$i => $a,\n  ";
    }
    push @list, "\n";
  }
  return @list;
}

# -------------------------------------------------------------------------------

sub nextcode {
  my $self = shift;
  
  my $fh = $self->{sock};
  my $in_block = 0;
  
  while(<$fh>){
    print "> ($in_block) $_" if $self->{debug};
    
    # Take care of response blocks
    if( /^\s*BEGIN\s*$/ ){ 
      die "got BEGIN inside a block from lircd: $_" if $in_block;
      $in_block = 1;
      next;
    }
    if( /^\s*END\s*$/ ){
      die "got END outside a block from lircd: $_" if! $in_block;
      $in_block = 0;
      next;
    }
    next if $in_block;

    # Decipher IR Command 
    # http://www.lirc.org/html/technical.html#applications
    # <hexcode> <repeat count> <button name> <remote name>
    my ($hex, $repeat, $button, $remote) = split /\s+/;
    defined $button and length $button or do {
      warn "Unable to decode.\n";
      next;
    };
    
    my %commands = %{$self->{commands}};
    my $cur_mode = $self->{mode};
    exists $commands{"$remote-$button-$cur_mode"} or next;
    my %command = %{$commands{"$remote-$button-$cur_mode"}};

    my $rep_count = 2**32;  # default repeat count
    if( defined $command{rep} && $command{rep} ){ $rep_count = $command{rep}; }
    
    if( hex($repeat) % $rep_count != 0 ){ next; }
    if( defined $command{mode} ){ $self->{mode} = $command{mode}; }

    print ">> $button accepted --> $command{conf}\n" if $self->{debug};
    return $command{conf};
  }
}

1;


__END__


=head1 NAME

Lirc::Client - A client library for the Linux Infrared Remote Control

=head1 SYNOPSIS

  use Lirc::Client;
  ...
  my $lirc = Lirc::Client->new( 'progname' );
  do {                            # Loop while getting ir codes
    my $code = $lirc->nextcode;    # wait for a new ir code
    print "Lirc> $code\n";        
    process( $code );              # do whatever you want with the code
  } while( defined $code );

=head1 DESCRIPTION

This module provides a simple interface to the Linux Infrared Remote 
Control (Lirc). The module encasuplates parsing the Lirc config file (.lircrc),
openning a connection to the Lirc device, and blocking while waiting for 
application specific IR commands.

=head2 Use Details

=over 4

=item new( program, [lircrc-file], [lircd-device], [debug-flag] )

  my $lirc = Lirc::Client->new( 'progname', "$ENV{HOME}/.lircrc", '/etc/lircd', 0 );
  
Defines the program token used in the Lirc config file, opens and parses
the Lirc config file (defaults to ~/.lircrc if none specified), connects to
the Lirc device (defaults to /etc/lircd if none specified), and returns the
Lirc::Client object. Pass a non-false debug-flag to have various debug
information printed (defaults to false).

=item nextcode()

  my $code = $lirc->nextcode;
  
Retrieves the next IR command associated with the B<progname> as defined in 
B<new()>, blocking if none is available. 

=item recognized_commands()

  my @list = $lirc->recongnized_commands();
  
Returns a list of all the recongnized commands for this application (as 
defined in the call to B<new()>.

=item clean_up()

  $lirc->clean_up();
  
Closes the Lirc device pipe, etc.

=back

=head1 SEE ALSO

=over 4

=item The Lirc Project - http://www.lirc.org

=item Remote Roadie - http://www.peculiarities.com/RemoteRoadie/ 

My suite of perl scripts which provide both a more powerful interface layer
between Lirc/Xmms, and various tools to manage your digital music files and
playlists.

=back

=head1 AUTHOR

Mark V. Grimes (mgrimes <at> alumni <dot> duke <dot> edu)

=head1 BUGS

None I am aware of. But B<recongnized_commands()> is relatively untested.
Need to report repeated keys to the client app. Maybe an event based
implementation should be added.
