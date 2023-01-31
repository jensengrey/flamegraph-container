FROM ubuntu:22.04

RUN apt update -y && apt upgrade -y
RUN apt install git -y
RUN apt install linux-tools-$(uname -r) linux-tools-generic -y
RUN git clone https://github.com/brendangregg/FlameGraph.git

WORKDIR /FlameGraph

# Add wrapper script
COPY _internal_mk-flamegraph.sh /usr/local/bin/_internal_mk-flamegraph
RUN chmod +x /usr/local/bin/_internal_mk-flamegraph

# Set the default command to run when starting the container
ENTRYPOINT ["/usr/local/bin/_internal_mk-flamegraph"]
