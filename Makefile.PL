require 5.000;
use ExtUtils::MakeMaker;

WriteMakefile (
	NAME				=> 'Lirc::Client',
	VERSION_FROM		=> 'lib/Lirc/Client.pm',
	($[ >= 5.005) ?
		(AUTHOR			=> 'Mark Grimes (mgrimes at cpan dot org)',
		 ABSTRACT		=> 'Module to provide a simple interface between Lirc and Perl client applications.'
		) : (),
	PREREQ_PM			=> {
					'IO::Socket'	=> '1.0',
					'Hash::Util'	=> 0,
					'Carp'			=> 0,
				},
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

