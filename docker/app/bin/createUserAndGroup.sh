#!/bin/bash
#I guess relative paths will be resolved to /app/
#due to WORKDIR directive, but for clarity 
#I am using absolute paths
#super secret and hard to guess pwd :))
#/etc/login.defs has USERGROUPS_ENAB set to yes
#so no need to create group, IPV group is auto
#created
useradd -m IPV;
chown -R root:IPV /app/;
chmod -R 775 /app/;
find /app/ -type f -print0 | xargs -0 chmod 774;