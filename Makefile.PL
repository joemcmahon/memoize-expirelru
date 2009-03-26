use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME		=> 'Memoize::ExpireLRU',
	      VERSION_FROM	=> 'ExpireLRU.pm', # finds $VERSION
	      PREREQ_PM => { Memoize => 0.52 , },
	      dist		=> {
				    COMPRESS => 'gzip',
				    SUFFIX => '.gz',
				   },
	     );
