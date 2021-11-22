FROM node:16

LABEL maintainer="Ibrahim Tanyalcin"
LABEL description="Mount volume with config.json \ 
to create html output"
LABEL version="1.0.12"
LABEL website="http://i-pv.org/"
LABEL repository="https://github.com/IbrahimTanyalcin/I-PV"

WORKDIR /app
RUN ["/bin/bash", "-c", "apt-get -y update"]
RUN ["/bin/bash", "-c", "apt-get -y install perl-doc"]
RUN ["/bin/bash", "-c", "apt-get -y install libgd-dev"]
RUN ["/bin/bash", "-c", "echo | cpan"]

#I am aware of the docker layers,
#however the idea is that dependencies are 
#installed from readme.
#An exeception below for GD library,
#which I guess is the heaviest.
RUN ["/bin/bash", "-c", "cpan install GD"]


COPY ./app/package*.json ./
RUN npm install
COPY ./app ./
RUN /bin/bash ./bin/installDeps.sh
RUN /bin/bash ./bin/setLogname.sh
RUN /bin/bash ./bin/createUserAndGroup.sh
# ENV LOGNAME="IPV" Alternative to setLogname.sh
ENV MOUNT_PATH="/app/mount"
# EXPOSE 3000 -no need for servers, 
USER IPV:IPV
ENTRYPOINT ["node", "main.js"]
CMD ["--no-daemon", "--input", "config.json"]