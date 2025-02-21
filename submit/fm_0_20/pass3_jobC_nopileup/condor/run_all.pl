#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $build;
my $incremental;
my $outevents = 0;
my $runnumber;
my $shared;
my $test;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "run:i" =>\$runnumber, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--run: <runnumber>\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
my $isbad = 0;

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub hosts\n";
    $isbad = 1;
}
if (! defined $runnumber)
{
    print "need runnumber with --run <runnumber>\n";
    $isbad = 1;
}

if (! defined $build)
{
    print "need build with --build <ana build>\n";
    $isbad = 1;
}
if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    $isbad = 1;
}

if ($isbad > 0)
{
    exit(1);
}

my $maxsubmit = $ARGV[0];

my $condorlistfile =  sprintf("condor.list");

if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d",$outdir,$runnumber);
mkpath($outdir);

my %trkhash = ();
my %clusterhash = ();


my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRACKSEEDS' and filename like 'DST_TRACKSEEDS_sHijing_0_20fm-%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $getclusterfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_CLUSTER' and filename like 'DST_CALO_CLUSTER_sHijing_0_20fm-%' and runnumber = $runnumber");

my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%06d",$res[1])} = $res[0];
}
$getfiles->finish();
$getclusterfiles->execute() || die $DBI::errstr;
my $ncluster = $getclusterfiles->rows;
while (my @res = $getclusterfiles->fetchrow_array())
{
    $clusterhash{sprintf("%06d",$res[1])} = $res[0];
}
$getclusterfiles->finish();

foreach my $segment (sort keys %trkhash)
{
    if (! exists $clusterhash{$segment})
    {
	next;
    }

    my $lfn = $trkhash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_TRACKS_sHijing_0_20fm-%010d-%06d.root",$runnumber,$segment);
	$chkfile->execute($outfilename);
	if ($chkfile->rows > 0)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $lfn, $clusterhash{sprintf("%06d",$segment)}, $outfilename, $outdir, $build, $runnumber, $segment, $tstflag);
	print "cmd: $subcmd\n";
	system($subcmd);
	my $exit_value  = $? >> 8;
	if ($exit_value != 0)
	{
	    if (! defined $incremental)
	    {
		print "error from run_condor.pl\n";
		exit($exit_value);
	    }
	}
	else
	{
	    $nsubmit++;
	}
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit>= 20000)
	{
	    print "maximum number of submissions reached, exiting\n";
	    last;
	}
    }
}
$chkfile->finish();
$dbh->disconnect;

my $jobfile = sprintf("condor.job");
if (defined $shared)
{
    $jobfile = sprintf("condor.job.shared");
}
if (-f $condorlistfile)
{
    if (defined $test)
    {
	print "would submit $jobfile\n";
    }
    else
    {
	system("condor_submit $jobfile");
    }
}
