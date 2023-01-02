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

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.339


if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    echo $2 > inputfiles.list
    echo $3 >> inputfiles.list
    getinputfiles.pl --filelist inputfiles.list
    if [ $? -ne 0 ]
    then
        cat inputfiles.list
	echo error from getinputfiles.pl --filelist inputfiles.list, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    hostname
    exit -1
fi

# arguments 
# $1: number of events
# $2: trkr seed input file
# $3: cluster input file
# $4: output file
# $5: output dir
# $6: jet trigger
# $7: run number
# $8: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(trkr seed file\): $2
echo arg3 \(cluster file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo arg6 \(jet trigger\): $6
echo arg7 \(runnumber\): $7
echo arg8 \(sequence\): $8

runnumber=$(printf "%010d" $7)
sequence=$(printf "%05d" $8)
filename=JS_pp200_signal_pass3_jobC_nopileup_$6

txtfilenameC=${filename}-${runnumber}-${sequence}_C.txt
jsonfilenameC=${filename}-${runnumber}-${sequence}_C.json

echo running prmon --filename $txtfilenameC --json-summary $jsonfilenameC -- root.exe -q -b Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$2\",\"$3\",\"$4\",\"$5\"\)
prmon --filename $txtfilenameC --json-summary $jsonfilenameC -- root.exe -q -b  Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$2\",\"$3\",\"$4\",\"$5\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/JS_pp200_signal/pass3_jobC_nopileup_$5
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilenameC $rsyncdirname
rsync -av $jsonfilenameC $rsyncdirname

echo "script done"
