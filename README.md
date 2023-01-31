# flamegraph-container

Demo of running [perf](https://www.brendangregg.com/perf.html) and [FlameGraph.pl](https://github.com/brendangregg/FlameGraph) inside of a container to convert perf traces into svg files.

This assumes your host is *also* running `ubuntu:22.04` as the kernel versions need to match.

# Create a new Ubuntu 22.04 VM

```
PROJECTID=<your project id>
gcloud compute instances create flamegraph-demo  \
    --project=$PROJECTID \
    --zone=us-west1-b \
    --machine-type=t2d-standard-4 \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --no-service-account \
    --no-scopes \
    --tags=http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=flamegraph-demo,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230114,mode=rw,size=30,type=projects/$PROJECTID/zones/us-west1-b/diskTypes/pd-ssd \
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

* https://trofi.github.io/posts/215-perf-and-dwarf-and-fork.html


# Convert perf trace data to SVG

```
perf-to-svg tar-g-lzma.perf.data tar-g-lzma.perf.svg
```

```
perf-to-svg tar-dwarf-zstd.perf.data tar-dwarf-zstd.perf.svg
```

# Output

![svg-perf-trace]()


# Enable capturing perf trace w/o sudo

```
sudo sh -c "echo -1 > /proc/sys/kernel/perf_event_paranoid"
```


