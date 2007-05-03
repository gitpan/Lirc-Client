use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
                 sub ACTION_dist {
                     print "Running cvs2cl.pl to create ChangeLog\n";
                     system( 'cvs2cl.pl' );
                     shift->SUPER::ACTION_dist(@_);
                 }
              },
);
my $build = $class->new(
	module_name				=> 'Lirc::Client',
	license					=> 'perl',
	# dist_version_from		=> 'lib/Lirc/Client.pm',
	# dist_name				=> 'name',
	create_readme			=>  1,
	create_makefile_pl		=>	'passthrough',
	requires				=> {
					'IO::Socket'	            => '1.0',
					'Hash::Util'	            => 0,
					'Class::Accessor::Fast'	    => 0,
					'Carp'			            => 0,
		},
	# recommends				=> {
	# 		'Test::Pod'				=> 0,
	# 	},
);

# $build->add_build_element('gif');
$build->create_build_script;

