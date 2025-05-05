CONTAINER_REPO ?= ghcr.io/alban/alterseccomp
IMAGE_TAG ?= latest

.PHONY: all
all: alterseccomp

.PHONY: alterseccomp
alterseccomp:
	CGO_ENABLED=0 go build \
        -ldflags "-extldflags '-static'" \
        -tags "netgo" \
        ./cmd/alterseccomp

ebpf-objects:
	docker run --rm --name ebpf-object-builder --user $(shell id -u):$(shell id -g) \
		-v $(shell pwd):/work $(GADGET_BUILDER) \
		make ebpf-objects-outside-docker

ebpf-objects-outside-docker:
# We need <asm/types.h> and depending on Linux distributions, it is installed
# at different paths:
#
# * Ubuntu, package linux-libc-dev:
#   /usr/include/x86_64-linux-gnu/asm/types.h
#
# * Fedora, package kernel-headers
#   /usr/include/asm/types.h
#
# Since Ubuntu does not install it in a standard path, add a compiler flag for
# it.
	TARGET=arm64 CFLAGS="-I/usr/include/$(shell uname -m)-linux-gnu -I$(shell pwd)/include/arm64/ -I$(shell pwd)/include/" go generate ./...
	TARGET=amd64 CFLAGS="-I/usr/include/$(shell uname -m)-linux-gnu -I$(shell pwd)/include/amd64/ -I$(shell pwd)/include/" go generate ./...

build-container:
	docker build -t $(CONTAINER_REPO):$(IMAGE_TAG) -f Dockerfile .
