# flamegraph-container

Demo of running [perf](https://www.brendangregg.com/perf.html) and [FlameGraph.pl](https://github.com/brendangregg/FlameGraph) inside of a container to convert perf traces into svg files.

This assumes your host is *also* running `ubuntu:22.04` as the kernel versions need to match.

# Create a new Ubuntu 22.04 VM

... exercise for the reader ...

# Install perf tools on the host

```
sudo bash -c 'apt update -y && apt upgrade -y'
sudo apt install linux-tools-$(uname -r) linux-tools-generic curl git binutils build-essential -y
```

# Install docker

```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

# Clone this repo

```
git clone https://github.com/jensengrey/flamegraph-container
```


# Build the docker image

```
cd flamegraph-container
sudo docker build -t flamegraph .
```

# Record a perf trace

This records perf events across all cores for 10 seconds

```
sudo perf record -g --output tar-g-lzma.perf.data -- tar -c --lzma -f include.tar.lzma /usr/include
```

also try

```
perf record --call-graph dwarf --output tar-dwarf-zstd.perf.data -- tar -c --zstd -f include.tar.zstd /usr/include
```

see below how to give perf access to all users.

`--call-graph dwarf` puts more load on the system than `-g` (we should measure this) but it is more reliable.

* https://trofi.github.io/posts/215-perf-and-dwarf-and-fork.html


# Convert perf trace data into an svg

```
perf-to-svg tar-g-lzma.perf.data tar-g-lzma.perf.svg
```

```
perf-to-svg tar-dwarf-zstd.perf.data tar-dwarf-zstd.perf.svg
```

# Output

![svg-perf-trace]()




----

```
sudo sh -c "echo -1 > /proc/sys/kernel/perf_event_paranoid"
```


