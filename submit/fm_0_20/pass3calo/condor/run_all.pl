#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $inrunnumber=6;
#my $outrunnumber=40;
my $outrunnumber=$inrunnumber;
my $test;
my $incremental;
my $shared;
GetOptions("test"=>\$test, "increment"=>\$incremental, "shared" => \$shared);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01 or phnxsub02\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}

my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d",$outdir,$inrunnumber);
if ($outdir =~ /lustre/)
{
    my $storedir = $outdir;
    $storedir =~  s/\/sphenix\/lustre01\/sphnxpro/sphenixS3/;
    my $makedircmd = sprintf("mcs3 mb %s",$storedir);
    system($makedircmd);
}
else
{
  mkpath($outdir);
}


my %calohash = ();
my %vtxhash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like 'DST_CALO_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm%' and runnumber = $inrunnumber order by filename") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $getvtxfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_VERTEX' and filename like 'DST_VERTEX_sHijing_0_20fm_50kHz_bkg_0_20fm%' and runnumber = $inrunnumber");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $calohash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();
$getvtxfiles->execute() || die $DBI::errstr;
my $nvtx = $getvtxfiles->rows;
while (my @res = $getvtxfiles->fetchrow_array())
{
    $vtxhash{sprintf("%05d",$res[1])} = $res[0];
}
$getvtxfiles->finish();
#print "input files: $ncal, vtx: $nvtx\n";
foreach my $segment (sort keys %calohash)
{
    if (! exists $vtxhash{$segment})
    {
	next;
    }

    my $lfn = $calohash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_CALO_CLUSTER_sHijing_0_20fm_50kHz_bkg_0_20fm-%010d-%05d.root",$outrunnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s", $outevents, $lfn, $vtxhash{sprintf("%05d",$segment)}, $outfilename, $outdir, $outrunnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >=20000)
	{
	    print "maximum number of submissions $nsubmit reached, exiting\n";
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
