#
# Preparation:
#   You need to download some software source cods by yourself, because of license.
#    - HTK-3.4.1.tar.gz
#    - HTK-samples-3.4.1.tar.gz
#    - srilm-1.7.2.tar.gz
#
# Prepare:
#  Install this file in %USERPFOILE%\Documents\OUSLP\docker
#
# Build:
#  PS> docker build -t ouslp/ouslp:2017 .
#
# Run (simple):
#  PS> docker run -it --rm ouslp/ouslp:2017 /bin/bash
#
# Run (share the local storage):
#  PS> docker run -it --rm -v $home/Documents:/work ouslp/ouslp:2017 /bin/bash
#

FROM centos:6.8
MAINTAINER Sunao Hara

# Setting environment
RUN mkdir -p /opt/SLP/src
RUN yum install -y tcsh man
RUN yum install -y perl
RUN yum install -y gcc gcc-c++ make
#RUN yum install -y SDL SDL-devel
RUN yum install -y sox
RUN yum install -y git

ENV PATH /opt/SLP/bin:$PATH
ENV MANPATH /opt/SLP/man

WORKDIR /opt/SLP/src

# Install SPTK
RUN curl -L http://downloads.sourceforge.net/sp-tk/SPTK-3.10.tar.gz -O; \
    tar xzf SPTK-3.10.tar.gz
RUN cd SPTK-3.10; \
    ./configure --prefix=/opt/SLP && make -j2 && make install

# Install mecab (core and dictionary)
RUN curl -L 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE' -o mecab-0.996.tar.gz; \
    tar xzf mecab-0.996.tar.gz
RUN cd mecab-0.996; \
    ./configure --prefix=/opt/SLP/ && make -j2 && make install

RUN curl -L 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM' -o mecab-ipadic-2.7.0-20070801.tar.gz; \
    tar xzf mecab-ipadic-2.7.0-20070801.tar.gz
RUN cd mecab-ipadic-2.7.0-20070801; \
    ./configure --prefix=/opt/SLP/ && make -j2 && make install

# Install Julius
RUN curl -L 'https://github.com/julius-speech/julius/archive/v4.3.1.tar.gz' -o julius-4.3.1.tar.gz; \
    tar xzf julius-4.3.1.tar.gz
RUN cd julius-4.3.1; \
    ./configure --prefix=/opt/SLP/ && make -j2 && make install

# Install HTK-3.4.1
ADD HTK-3.4.1.tar.gz /opt/SLP/src/
ADD HTK-samples-3.4.1.tar.gz /opt/SLP/src/htk

WORKDIR /opt/SLP/src/htk
RUN CFLAGS=-m64 ./configure --prefix=/opt/SLP --disable-hslab --disable-hlmtools && make all && make install
RUN cp samples/HTKDemo/MakeProtoHMMSet /opt/SLP/bin/

# Install SRILM-1.7.2
ADD srilm-1.7.2.tar.gz /opt/SLP/srilm-1.7.2

WORKDIR /opt/SLP/srilm-1.7.2
ENV SRILM /opt/SLP/srilm-1.7.2
RUN make -j2 World
ENV PATH $SRILM/bin/x86_64:$SRILM/bin:$PATH
ENV MANPATH $SRILM/man:$MANPATH


# Finish
WORKDIR /work
