#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests=>5;

use_ok( "IO::Select"   );
use_ok( "Lirc::Client" );

my $lirc=Lirc::Client->new( {
		prog	=> "lirc-client-test",
		rcfile	=> "samples/lircrc.2",
		debug	=> 0,
		fake	=> 1,
	} );
ok( $lirc, "created a lirc object");

pipe my $read, my $write or die $!;
$lirc->{sock} = $read;
print $write "0 0 play test-remote\n";
print $write "0 0 pause test-remote\n";
close $write;

my @codes = qw/PLAY PAUSE/;
my $count = 0;

my $select = IO::Select->new();
$select->add( $lirc->sock );
while(1){
	# do your own stuff, if you want
	if( my @ready = $select->can_read(0) ){
		# an ir event has been received
		# may not be a full line from lirc, but I have never seen one
		my $code = $lirc->next_code;	# should not block
		process( $code );
	}
}

sub process {
	my $code = shift;

	is( $code, shift @codes, "recognized command " . ++$count );
	exit if $count > 1;
}
