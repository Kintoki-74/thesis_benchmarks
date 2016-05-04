#!/bin/bash
scenarioname=""
soaversion=""

if [ $# -lt 1 ]; then
    echo "Usage: ./gproffilter <scenario> [simdrp|inlinerp]";
    echo "scenario is one of \"<dry|wet|chile>_<vanilla|soa>\""
    exit
else
    scenarioname="${1}_gprof"
    if [ $# -eq 2 ]; then
        soaversion="_*${2}rp"
    fi
fi

filename="${scenarioname}_percentages"
echo "Writing to ${filename}"
#echo -e "N\t Calls\t Time\t GFLOPS\t Rims" > $filename
> $filename

srs=("rpn2" "rpt2" "flux2" "step2")

for s in ${srs[@]}; do
    echo -ne "${s}\t" >> $filename
    for d in `ls | grep "run_${scenarioname}${soaversion}*"`;
    do
        n=`echo $d | sed -e 's/.*_\([0-9]*\)__.*/\1/'`;
        line=`gprof $d/xgeoclaw* $d/_output/gmon.out | grep "^ *[0-9].* ${s}_$"`
        #echo $n $line

        subroutine=`grep -oE '[^ ]+$' <<< ${line};`
        percentage=`sed -e "s/ *\([0-9\.]*\).*/\1/" <<< ${line}`;
        if [[ $percentage == "" ]]; then percentage="0"; fi
        echo -en "${percentage}\t" >> $filename
    done
    echo >> $filename
done

