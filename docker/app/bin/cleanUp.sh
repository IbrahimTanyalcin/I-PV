#!/bin/bash
#dpkg-query -Wf '${Installed-Size}\t${Package}:${Version}' | sort -n
#above to get list of binaries installed
#merging the RUN commands in the dockerfile using 
#shell form does not seem to cut down the image size.
#Executing the commands below should normally remove
#around 200mb of data, however that is not reflected
#in the final image size either
apt-get -y remove --purge git;
apt-get clean;
rm -rf /var/lib/apt/lists/*;
npm cache clean --force;