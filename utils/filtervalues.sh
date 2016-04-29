#!/bin/bash
scenarioname=""
soaversion=""

if [ $# -lt 1 ]; then
    echo "Usage: ./filtervalues <scenario> [simdrp|inlinerp]";
    echo "scenario is one of \"<dry|wet|chile>_<vanilla|soa>\""
    exit
else
    scenarioname="${1}_papi"
    if [ $# -eq 2 ]; then
        soaversion="_*${2}rp"
    fi
fi

filename="${scenarioname}_values"
echo "Writing to ${filename}..."
#echo -e "N\t Calls\t Time\t GFLOPS\t Rims" > $filename
> $filename
for f in `ls run_${scenarioname}${soaversion}*/_output/riemannstats.log`;
do
    n=`echo $f | sed -e 's/.*_\([0-9]*\)__.*/\1/'`;
    values=`sed -ne '5s/  */\t /gp' $f`
    values="${values}`sed -ne '8s/\( *[0-9\.]*\).*/\1/p' $f`"
    #values=`sed -ne '5s/ *[0-9]* * [0-9.]* *\([0-9.]\)/\1 /p' $f`
    echo "$n $values" >> $filename
done
