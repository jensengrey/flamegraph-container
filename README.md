# flamegraph-container

Demo of running [perf](https://www.brendangregg.com/perf.html) and [FlameGraph.pl](https://github.com/brendangregg/FlameGraph) inside of a container to convert perf traces into svg files.

This assumes your host is *also* running `ubuntu:22.04` as the kernel versions need to match.

This guide is designed to run you through installing a system from scratch and capturing perf traces and converting them into SVG. 

https://jvns.ca/perf-cheat-sheet.pdf

# Create a new Ubuntu 22.04 VM

```
PROJECT_ID=$(gcloud config get-value project)
gcloud compute instances create flamegraph-demo  \
    --project=$PROJECT_ID \
    --zone=us-west1-b \
    --machine-type=t2d-standard-4 \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --no-service-account \
    --no-scopes \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=flamegraph-demo,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230114,mode=rw,size=30,type=projects/$PROJECT_ID/zones/us-west1-b/diskTypes/pd-ssd \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

```

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
mkdir ~/bin
cp perf-to-svg ~/bin
source ~/.profile # puts ~/bin in your path
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

# Convert perf trace data to SVG

```
perf-to-svg tar-g-lzma.perf.data tar-g-lzma.perf.svg
```

```
perf-to-svg tar-dwarf-zstd.perf.data tar-dwarf-zstd.perf.svg
```

# Output

## zstd, dwarf

![zstd-dwarf perf trace](https://raw.githubusercontent.com/jensengrey/flamegraph-container/main/sample-data/tar-dwarf-zstd.perf.svg)

## zstd, -g

![zstd-g perf trace](https://raw.githubusercontent.com/jensengrey/flamegraph-container/main/sample-data/tar-g-zstd.perf.svg)

## lzma, -g

![lzma-g perf trace](https://raw.githubusercontent.com/jensengrey/flamegraph-container/main/sample-data/tar-g-lzma.perf.svg)

## lzma, dwarf

![lzma-dwarf perf trace](https://raw.githubusercontent.com/jensengrey/flamegraph-container/main/sample-data/tar-dwarf-lzma.perf.svg)


# Enable capturing perf trace w/o sudo

This also prevents your entire command from running as root and the files it writes from being owned by root.

Recommended

```
sudo sh -c "echo -1 > /proc/sys/kernel/perf_event_paranoid"
sudo sh -c "echo 0 > /proc/sys/kernel/kptr_restrict"
```

# Better debug information from system packages

Good traces require good debugging information. 

* https://trofi.github.io/posts/215-perf-and-dwarf-and-fork.html
* https://wiki.debian.org/HowToGetABacktrace

Enable `deb-src` in your `/etc/apt/sources.lst`

```
sudo vim /etc/apt/sources.list
# %s/# deb-src/deb-src/g
sudo apt-get update
```

## install tools to rebuild deb package from source deb

```
sudo apt-get install devscripts fakeroot gdb build-essential
sudo apt-get build-dep <package>
DEB_BUILD_OPTIONS="debug nostrip noopt" apt -b source <package>
sudo dpkg -i <build artifact.deb>
```

## example

*note, `apt-get` and `apt get` are distinct, we need apt-get for build-dep*

```
sudo apt-get build-dep hello
DEB_BUILD_OPTIONS="debug nostrip noopt" apt -b source hello
sudo dpkg -i hello_2.10-2ubuntu4_amd64.deb
```

```
$ file /usr/bin/hello
/usr/bin/hello: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=afd5b7bb06382b28094d490740046feac1eb0f95, for GNU/Linux 3.2.0, with debug_info, not stripped
```

Notice the `with debug_info, not stripped` at the end.

# Viewing remote files

## SSH Tunnel

```
# on the remote vm
python3 -m http.server --bind 127.0.0.1 4070

# from your laptop
gcloud compute ssh --zone "us-central1-a" "<vm name>"  --project "<project>" -- -L 4070:localhost:4070
```

## Public HTTP Server

```
sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3.10

# do not run directly from your home directory
# someone can ready your private .ssh keys, etc
python3 -m http.server 80
```



