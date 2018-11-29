#! /bin/bash

UUUPSTREAM_PATCHES="/home/ubuntu/test_commits.txt"
IP_KEYWORDS_CFG="/home/ubuntu/keywords.cfg"
KERNEL_SRC_DIR="/home/ubuntu/linux"
REPORT_FILE="/home/ubuntu/report.csv"

IP[0]=""
KEYWORDS[0]=""
PATCHNUM[0]=0
COMMITS[0]=""
IP_NUM=0


init_variable() {
    i=0
    while (($i < $IP_NUM)); do
        PATCHNUM[i]=0
        COMMITS[i]=""
        i=$((i+1))
    done
}

get_ip_keywords() {
    i=0
    while read line; do
        IP[$i]=`echo $line | awk -F ':' '{print $1}'`
        KEYWORDS[$i]=`echo $line | awk -F ':' '{print $2}'`
        i=$((i+1))
    done < $IP_KEYWORDS_CFG
    IP_NUM=$i
}

generate_report() {
    i=0
    matched=0
    echo "Seq,IP,Patch number,Patch List" > $REPORT_FILE
    while (($i < $IP_NUM)); do
        echo -e "$i, ${IP[$i]}, ${PATCHNUM[$i]}, \"${COMMITS[$i]}\""  >> $REPORT_FILE
        echo -e "$i --- ${IP[$i]} --- ${PATCHNUM[$i]} --- ${COMMITS[$i]}"
        echo "#############################################################################"
        i=$((i+1))
    done
    echo -e "$i, "undefined", ${PATCHNUM[$i]}, \"${COMMITS[$i]}\""  >> $REPORT_FILE
    echo -e "$i --- "undefined" --- ${PATCHNUM[$i]} --- ${COMMITS[$i]}"
}

triage_patches() {
    cd $KERNEL_SRC_DIR
    seq=0
    while read line; do
        seq=$((seq+1))
        echo "Processing the $seq patch: $line"
    
        commit=`echo $line | awk '{print $1}'`
    
        subject=`git show -s --format=%s $commit`
        subject=`echo $subject | sed -r 's/"//g'`
        changes=`git diff-tree --no-commit-id --name-only -r $commit`
    
        i=0
        matched=0
        while (($i < $IP_NUM)); do
            keywords=${KEYWORDS[$i]}
            keywords=`echo $keywords | sed -r 's/,/ /g'`
    
            for keyword in $keywords; do
                matched=`echo $changes | grep $keyword | wc -l`
                if [ "$matched" != '0' ]; then
                    PATCHNUM[$i]=$((${PATCHNUM[$i]}+1))
                    COMMITS[$i]="${COMMITS[$i]} $commit-$subject\n"
                    break
                fi
            done
    
            if [ "$matched" == "0" ]; then 
                for keyword in $keywords; do
                    matched=`echo $subject | grep $keyword | wc -l`
                    if [ "$matched" != '0' ]; then
                        PATCHNUM[$i]=$((${PATCHNUM[$i]}+1))
                        COMMITS[$i]="${COMMITS[$i]} $commit=$subject\n"
                        break
                    fi
                done
            fi
    
            if [ "$matched" == "0" ]; then
                i=$((i+1))
                continue
            else
                matched=0
                break
            fi
        done
    
        if [ "$i" = "$IP_NUM" ]; then
            PATCHNUM[$i]=$((${PATCHNUM[$i]}+1))
            COMMITS[$i]="${COMMITS[$i]} $commit-$subject\n"
        fi
    done < $UUUPSTREAM_PATCHES
}

# Init variables
init_variable
# Read the keywords of IP
get_ip_keywords
# Triage patches
triage_patches
# Generate report
generate_report
