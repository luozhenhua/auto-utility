#!/bin/bash

# Get all installed packages from ubuntu repository
apt list --installed > pkg_list.txt

# initialication
i=0
echo > pkg_source_repo.csv

# Analysis the source repo and write to pkg_source_repo.csv
while read LINE
do
  if [ "$i" == "0" ]; then
    i=$((i+1))
    continue
  fi
  pn=`echo $LINE | awk -F '/' '{print $1}'`;
  src=`apt show $pn | grep APT-Sources`;
  url=`echo $src | awk '{print $2}'`;
  repo=`echo $src | awk '{print $3}'`;
  if [ "`echo \"$src\" | grep '/main'`" == "" ];
  then
    printf "%s,%s,%s,%s,%s\n" "$i" "non-main" "$pn" "$repo" "$url" >> pkg_source_repo.csv;
  else
    printf "%s,%s,%s,%s,%s\n" "$i" "main" "$pn" "$repo" "$url" >> pkg_source_repo.csv;
  fi
  i=$((i+1));
done < pkg_list.txt 

