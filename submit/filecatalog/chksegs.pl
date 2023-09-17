#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

my $system = 0;
my $verbosity;
my $nopileup;
my $runnumber = 6;
my $embed;
my $ptmin;
my $ptmax;
my $mom;
my $particle;
my $file_exist_check;
GetOptions("embed:s" => \$embed, "exist" => \$file_exist_check, "run:i"=>\$runnumber, "type:i"=>\$system, "verbosity" => \$verbosity, "nopileup" => \$nopileup);

if ($system < 1 || $system > 21)
{
    print "use -type, valid values:\n";
    print "-type : production type\n";
    print "    1 : hijing (0-12fm) pileup 0-12fm\n";
    print "    2 : hijing (0-4.88fm) pileup 0-12fm\n";
    print "    3 : pythia8 pp MB\n";
    print "    4 : hijing (0-20fm) pileup 0-20fm\n";
    print "    5 : hijing (0-12fm) pileup 0-20fm\n";
    print "    6 : hijing (0-4.88fm) pileup 0-20fm\n";
    print "    7 : HF pythia8 Charm\n";
    print "    8 : HF pythia8 Bottom\n";
    print "    9 : HF pythia8 CharmD0\n";
    print "   10 : HF pythia8 BottomD0\n";
    print "   11 : JS pythia8 Jet >30GeV\n";
    print "   12 : JS pythia8 Jet >10GeV\n";
    print "   13 : JS pythia8 Photon Jet\n";
    print "   14 : Single Particle\n";
    print "   16 : HF D0 Jet\n";
    print "   17 : HF pythia8 D0 pi-k Jets ptmin = 5GeV\n";
    print "   18 : HF pythia8 D0 pi-k Jets ptmin = 12GeV\n";
    print "   19 : JS pythia8 Jet >40GeV\n";
    print "   20 : hijing pAu (0-10fm) pileup 0-10fm\n";
    print "   21 : JS pythia8 Jet >20GeV\n";
    exit(0);
}

my $systemstring;
my $systemstring_g4hits;
my $g4hits_exist = 0;
my $gpfsdir = "sHijing_HepMC";
my %notlike = ();
if ($system == 1)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_12fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_12fm",$systemstring_g4hits);
}
elsif ($system == 2)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_488fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_12fm",$systemstring_g4hits);
}
elsif ($system == 3)
{
#    $systemstring = "pythia8_pp_mb";
    $g4hits_exist = 1;
    $systemstring_g4hits ="pythia8_pp_mb";
    $gpfsdir = "pythia8_pp_mb";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }

}
elsif ($system == 4)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_20fm";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_50kHz_bkg_0_20fm",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 5)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_12fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_20fm",$systemstring_g4hits);
}
elsif ($system == 6)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_488fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_20fm",$systemstring_g4hits);
}
elsif ($system == 7)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Charm";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 8)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Bottom";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 9)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_CharmD0";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 10)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_BottomD0";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 11)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Jet30";
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		if ($embed eq "auau")
		{
		    $systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
		}
		elsif ($embed eq "pau")
		{
		    $systemstring = sprintf("%s_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm",$systemstring_g4hits);
		}
		else
		{
		    print "bad embed val: $embed, valid values auau, pau\n";
		    exit(0);
		}
	    }
	    else
	    {
		$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "js_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 12)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Jet10";
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		if ($embed eq "auau")
		{
		    $systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
		}
		elsif ($embed eq "pau")
		{
		    $systemstring = sprintf("%s_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm",$systemstring_g4hits);
		}
		else
		{
		    print "bad embed val: $embed, valid values auau, pau\n";
		    exit(0);
		}
	    }
	    else
	    {
		$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "js_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 13)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_PhotonJet";
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		$systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
	    }
	    else
	    {
		$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "js_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 14)
{
    if ($#ARGV == 4)
    {
        $particle = $ARGV[1];
        $mom = $ARGV[2];
	$ptmin = $ARGV[3];
	$ptmax = $ARGV[4];
    }
    else
    {
	print "needs arguments particle p or pt ptmin ptmax\n";
        exit(1)
    }
    $g4hits_exist = 1;
    $systemstring = sprintf("single_%s_%s_%d_%dMeV",$particle,$mom,$ptmin,$ptmax);
    $systemstring_g4hits = sprintf("single_%s_%s_%d_%dMeV",$particle,$mom,$ptmin,$ptmax);
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		$systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "multiple_particle";
    print "systemstring_g4hits: $systemstring_g4hits\n";
    print "systemstring: $systemstring\n";
}

elsif ($system == 16)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_JetD0";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 17)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_CharmD0piKJet5";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 18)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_CharmD0piKJet12";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 19)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Jet40";
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		$systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
	    }
	    else
	    {
		$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "js_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 20)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_pAu_0_10fm";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_500kHz_bkg_0_10fm",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 21)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Jet20";
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		if ($embed eq "auau")
		{
		    $systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
		}
		elsif ($embed eq "pau")
		{
		    $systemstring = sprintf("%s_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm",$systemstring_g4hits);
		}
		else
		{
		    print "bad embed val: $embed, valid values auau, pau\n";
		    exit(0);
		}
	    }
	    else
	    {
		$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "js_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
else
{
    die "bad type $system\n";
}

open(F,">missing.files");
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $conds = sprintf("filename like \'\%%%s%\%\' and runnumber = %s",$systemstring,$runnumber);
if (exists $notlike{$systemstring})
{
    my $ref = $notlike{$systemstring};
    foreach my $item  (@$ref)
    {
	$conds = sprintf("%s and filename not like  \'\%%%s%\%\'",$conds,$item);
    }
}
$conds = sprintf("%s order by dsttype",$conds);
my $sqlcmd = sprintf("select distinct(dsttype) from datasets where %s", $conds);
#print "$sqlcmd\n";
my $getdsttypes = $dbh->prepare($sqlcmd);
my %topdcachedir = ();
#$topdcachedir{sprintf("/pnfs/rcf.bnl.gov/sphenix/disk/MDC2/%s",$gpfsdir)} = 1;
#$topdcachedir{sprintf("/sphenix/lustre01/sphnxpro/dcsphst004/mdc2/%s",lc $gpfsdir)} = 1;
$topdcachedir{sprintf("/sphenix/lustre01/sphnxpro/mdc2/%s",lc $gpfsdir)} = 1;

if ($#ARGV < 0)
{
    print "available types:\n";

    $getdsttypes->execute();
    while (my @res = $getdsttypes->fetchrow_array())
    {
	print "$res[0]\n";
    }
    if ($g4hits_exist == 1)
    {
	print "G4Hits\n";
    }
    exit(1);
}


my $type = $ARGV[0];
if ($g4hits_exist == 1 && $type eq "G4Hits")
{
    $systemstring = $systemstring_g4hits;
}
$conds = sprintf("dsttype = ? and  filename like \'\%%%s%\%\' and runnumber = %d",$systemstring,$runnumber);
if (exists $notlike{$systemstring})
 {
    my $ref = $notlike{$systemstring};
    foreach my $item  (@$ref)
    {
	$conds = sprintf("%s and filename not like  \'\%%%s%\%\'",$conds,$item);
    }
}
$conds = sprintf("select segment,filename from datasets where %s order by segment",$conds);
if (defined $verbosity)
    {
        print "$conds\n";
    }
my $getsegments = $dbh->prepare($conds)|| die $DBI::errstr;

$conds = sprintf("dsttype = ? and  filename like \'\%%%s%\%\' and runnumber = %d",$systemstring,$runnumber);
if (exists $notlike{$systemstring})
 {
    my $ref = $notlike{$systemstring};
    foreach my $item  (@$ref)
    {
	$conds = sprintf("%s and filename not like  \'\%%%s%\%\'",$conds,$item);
    }
}
$conds = sprintf("select max(segment) from datasets where %s",$conds);

my $getlastseg = $dbh->prepare($conds)|| die $DBI::errstr;

$getlastseg->execute($type)|| die $DBI::errstr;;
my @res = $getlastseg->fetchrow_array();
if (! defined $res[0])
{
    print "no entries for $type, $systemstring\n";
    exit(0);
}
my $lastseg = $res[0];

$getsegments->execute($type);
my %seglist = ();
while (my @res = $getsegments->fetchrow_array())
{
    $seglist{$res[0]} = $res[1];
}
my $nsegs_gpfs = keys %seglist;
print "number of segments processed:  $nsegs_gpfs\n";
my $typeWithUnderscore = sprintf("%s",$type);
foreach my $dcdir (keys  %topdcachedir)
{
#    if ($type eq "DST_TRUTH" || $type eq "G4Hits")
    {
	$typeWithUnderscore = sprintf("%s_%s-%010d",$type,$systemstring,$runnumber);
#        print "type: $type\n";
#        print "systemstring: $systemstring\n";
#        print "typeWithUnderscore: $typeWithUnderscore\n";
    }
    $conds = sprintf("datasets.runnumber = %d and datasets.filename = files.lfn and files.lfn like \'%s%\%\' and files.full_file_path like \'%s/\%%%s%\%\'",$runnumber,$typeWithUnderscore,$dcdir,$type);
if (exists $notlike{$systemstring})
 {
    my $ref = $notlike{$systemstring};
    foreach my $item  (@$ref)
    {
	$conds = sprintf("%s and filename not like  \'\%%%s%\%\'",$conds,$item);
    }
}

    $conds = sprintf("select files.lfn,files.full_file_path from files,datasets where %s",$conds);
#    print "$conds\n";
    my $getsegsdc = $dbh->prepare($conds);
    if (defined $verbosity)
    {
        print "$conds\n";
    }
    $getsegsdc->execute();
    my $rows = $getsegsdc->rows;
    print "entries for $dcdir: $rows\n";
    if (defined $file_exist_check)
    {
	while (my @fullfile = $getsegsdc->fetchrow_array())
	{
	    if (! -f $fullfile[1])
	    {
		print "missing file $fullfile[1]\n";
	    }
	}
    }
    $getsegsdc->finish();
}
my $lowercasegpfsdir = lc $gpfsdir;
my $chklfn = $dbh->prepare("select lfn from files where lfn = ? and (full_file_path like '/pnfs/rcf.bnl.gov/sphenix/disk/MDC2/$gpfsdir/%' or full_file_path like '/sphenix/lustre01/sphnxpro/dcsphst004/mdc2/$lowercasegpfsdir/%' or full_file_path like '/sphenix/lustre01/sphnxpro/mdc2/$lowercasegpfsdir/%')");
for (my $iseg = 0; $iseg <= $lastseg; $iseg++)
{
    if (!exists $seglist{$iseg})
    {
	print "segment $iseg missing\n";
	next;
    }
    else
    {
	$chklfn->execute($seglist{$iseg});
	if ($chklfn->rows == 0)
	{
	    print F "$seglist{$iseg}\n";
	    print "$seglist{$iseg} missing\n";
	}
    }
}
close(F);
$chklfn->finish();
$getsegments->finish();
$getlastseg->finish();
$getdsttypes->finish();
$dbh->disconnect;
