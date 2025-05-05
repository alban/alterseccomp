FROM golang:1.24.2-bullseye@sha256:f0fe88a509ede4f792cbd42056e939c210a1b2be282cfe89c57a654ef8707cd2 AS builder

# Cache go modules so they won't be downloaded at each build
COPY go.mod go.sum /src/
RUN cd /src && go mod download

COPY ./ /src
RUN \
	--mount=type=cache,target=/root/.cache/go-build \
	--mount=type=cache,target=/go/pkg \
	cd /src && make

FROM busybox@sha256:9ae97d36d26566ff84e8893c64a6dc4fe8ca6d1144bf5b87b2b85a32def253c7
COPY --from=builder /src/alterseccomp /bin/alterseccomp
ENTRYPOINT ["/bin/alterseccomp"]
