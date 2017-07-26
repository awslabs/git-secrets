FROM ubuntu:latest

RUN apt-get -y update

RUN apt-get install -y git make

RUN git clone https://github.com/awslabs/git-secrets.git

RUN cd git-secrets && \
	make install && \
	make test
