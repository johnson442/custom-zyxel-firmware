FROM yamamuteki/ubuntu-lucid-i386

WORKDIR /tmp

RUN sed -i 's/archive/old-releases/' /etc/apt/sources.list

RUN echo "dash dash/sh boolean false" | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

RUN apt-get update && apt-get install -y unzip bzip2 patch \
    g++ flex bison gawk make autoconf zlib1g-dev libcurses-ocaml-dev libncurses-dev 



