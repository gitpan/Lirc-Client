#!/usr/bin/perl -w

use strict;
use warnings;

use Test;

BEGIN { plan tests => 3 }  # , todo => [4,5] }

# Test 1 -- can we load the library?
eval { use Lirc::Client; return 1;};
ok($@,'');
croak() if $@;  # If module didn't load... bail hard now

# Test 2 -- can we create an new client based on rroadie?
my $lirc = Lirc::Client->new( 'rroadie', 'samples/lircrc' );
ok $lirc;

# Test 3 -- can we get the command list?
my @commands = $lirc->recognized_commands;
my $commands = join('',@commands);

my $commands_key = <<"END_COMMANDS";
son-cable-CABLE_PLAY-:
  conf => PLAY,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_PAUSE-:
  conf => PAUSE,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_ONE-:
  conf => 1,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_REWIND-:
  conf => PREV,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_TWO-:
  conf => 2,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_THREE-:
  conf => 3,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_RECALL-:
  conf => SHUFFLE,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_STOP-:
  conf => STOP,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_FOUR-:
  conf => 4,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_SIX-:
  conf => 6,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_NINE-:
  conf => 9,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_VOL_UP-:
  conf => VOL_UP,
  flag => undef,
  rep => 8,
  mode => undef,
  
son-cable-CABLE_EIGHT-:
  conf => 8,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_PIP-:
  conf => FUNC,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_VOL_DOWN-:
  conf => VOL_DOWN,
  flag => undef,
  rep => 8,
  mode => undef,
  
son-cable-CABLE_FORWARD-:
  conf => NEXT,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_SEVEN-:
  conf => 7,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_ZERO-:
  conf => 0,
  flag => undef,
  rep => undef,
  mode => undef,
  
son-cable-CABLE_FIVE-:
  conf => 5,
  flag => undef,
  rep => undef,
  mode => undef,
  
END_COMMANDS

ok( $commands, $commands_key);
