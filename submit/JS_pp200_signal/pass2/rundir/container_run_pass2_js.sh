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

anabuild=${6}

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n $anabuild

cdbtag=MDC2_$anabuild


# arguments 
# $1: number of output events
# $2: input file
# $3: background listfile
# $4: output directory
# $5: jettrigger
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(input file\): $2
echo arg3 \(background listfile\): $3
echo arg4 \(output dir\): $4
echo arg5 \(jettrigger\): $5
echo arg6 \(build\): $6
echo arg7 \(pileup\): $7
echo arg8 \(runnumber\): $8
echo arg9 \(sequence\): $9
echo cdbtag: $cdbtag

runnumber=$(printf "%010d" $8)
sequence=$(printf "%06d" $9)

filename=timing

echo running root.exe -q -b Fun4All_G4_Pileup_pp.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",$7,\"$cdbtag\"\)
root.exe -q -b  Fun4All_G4_Pileup_pp.C\($1,\"$2\",\"$3\",\"$4\",\"$5\",$7,\"$cdbtag\"\)

timedirname=/sphenix/sim/sim01/sphnxpro/mdc2/logs/js_pp200_signal/pass2/timing.run${6}/${5}/${7}kHz

[ ! -d $timedirname ] &&  mkdir -p $timedirname

rootfilename=${timedirname}/${filename}-${runnumber}-${sequence}.root

[ -f jobtime.root ] && cp -v jobtime.root $rootfilename

echo "script done"
