use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Plua',
    VERSION_FROM      => 'lib/Plua.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.010 ? 
      (ABSTRACT_FROM  => 'lib/Plua.pm', # retrieve abstract from module
       AUTHOR         => 'terrencehan <hanliang1990@gmail.com>') : ()),
);
