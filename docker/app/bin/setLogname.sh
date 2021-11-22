#!/bin/bash
#circos will try to use $ENV{'LOGNAME'} at 
#lib/Circos/Configuration.pm 
#I guess in Windows this non-existent env var
#will return "" but, inside docker it returns 
#undef which Perl complains about
#I will not modify circos to replace it 
#with a ternary, because idk whether it
#might affect other modules
#check https://github.com/moby/moby/issues/25388
#apparently below needs to be sourced explicity
echo "Setting env LOGNAME to \'IPV\'";
echo "export LOGNAME=\"IPV\";" >> "/etc/bash.bashrc";
source /etc/bash.bashrc;