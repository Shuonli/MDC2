#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

anabuild=ana.418

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi
# arguments 
# $1: number of events
# $2: calo g4hits input file
# $3: output file
# $4: output dir
# $5: run number
# $6: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(calo g4hits file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $5)
sequence=$(printf "%06d" $6)

filename=timing

echo running root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\"\)
root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\",\"$cdbtag\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/ampt/pass2calo_nopileup_nozero/timing.run${5}

[ ! -d $timedirname ] && mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
