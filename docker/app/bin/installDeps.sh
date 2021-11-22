#!/bin/bash
#grep flags:
#i = case insensitive
#c = count the occurence instead of returning matched string
#E = extended syntax
#o = return the match rather than the whole string
flagIpvDepFound=0;
ipvDeps=();
circosDeps=();
ipvMissingDeps=();
#STEP 1 - get ipv deps
#read readme into array split by newlines
readarray -t ipvAllLines < <(cat node_modules/ibowankenobi-i-pv/i-pv/ReadMe.md);
#go through all lines until you are done extracting deps
for ipvLine in "${ipvAllLines[@]}"; do
  #break out if you bump into circos modules
  #i will use built-in circos --modules for those
  if [ $(echo $ipvLine | grep -icE 'circos\s*perl\s*modules') == 1 ];
  then
    break;
  fi;
  if [ $flagIpvDepFound -eq 1 ];
  then
    #skip empty lines
    if [ $(grep -vicE '^\s*$' <<< "$ipvLine") == 1 ];
    then 
      #extract the module name
      ipvDeps+=($(grep -ioE '[A-Z]+(?:[:]{0,2}[A-Z0-9]+)*' <<< "$ipvLine"));
    fi;
  continue;
  fi;
  #once found the right header start recording dependencies
  if [ $(echo $ipvLine | grep -icE 'i-pv\s*perl\s*modules') == 1 ];
  then
    #signal the flag for extraction
    flagIpvDepFound=1;
  fi;
done;

for i in ${!ipvDeps[@]}; do
  #z flag checks for null which perldoc -l returns 
  #when no file is found
  if [ -z $(perldoc -l ${ipvDeps[$i]}) ];
  then
    ipvMissingDeps+=(${ipvDeps[$i]});
  fi;
done;

#STEP 2 - get circos deps
#circos --modules gives missing mods 
#Ex: 'missing Config::General'
readarray -t circosDeps < <(perl node_modules/ibowankenobi-i-pv/circos/bin/circos --modules);
for i in ${!circosDeps[@]}; do
  if [ $(echo ${circosDeps[$i]} \
  | cut -d ' ' -f1 \
  | grep -icE 'miss' ) == 1 ];
  then
    ipvMissingDeps+=($(echo ${circosDeps[$i]} | cut -d ' ' -f2));
  fi;
done;
#keep the unique modules from
#STEP 1 and STEP 2
ipvMissingDeps=($(echo "${ipvMissingDeps[@]}" \
| tr ' ' '\n' \
| sort -u \
| tr '\n' ' '));

for ipvDep in ${ipvMissingDeps[@]}; do
  cpan install $ipvDep;
done;