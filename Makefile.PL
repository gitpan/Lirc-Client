require 5.000;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME				=> 'Lirc::Client',
	VERSION_FROM		=> 'lib/Lirc/Client.pm',
	# VERSION				=> '1.1',
	($[ >= 5.005) ?
		(AUTHOR			=> 'Mark Grimes (mgrimes@cpan.org)',
		 ABSTRACT		=> 'Module to provide a simple interface between Lirc and Perl client applications.'
		) : (),
	dist					=>	{ 
						PREOP	=> ('cvs2cl.pl; '.
											'cp -f ChangeLog $(DISTVNAME);'.
											'rm -f README; '.  								 
											'cp README.head README; '.
											'pod2text -80 < lib/Lirc/Client.pm >> README; '.
											'cp -f README $(DISTVNAME); '			# Changes 
										 ),
										},
);

