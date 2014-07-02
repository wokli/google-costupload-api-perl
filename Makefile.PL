use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Google::CostUploadAPI',
    VERSION_FROM      => 'lib/Google/CostUploadAPI.pm', # finds $VERSION
    PREREQ_PM         => {'LWP::UserAgent' => 6.06}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ? (ABSTRACT  => 'Dumb perl wrapper for google cost upload api', AUTHOR => 'alexn <alexn@mm.st>') : ()),
);
