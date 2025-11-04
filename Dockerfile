FROM golang:1.24 AS builder

WORKDIR /build

COPY go.mod go.sum ./

# Download dependencies with cache mount
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY ./cmd /build/cmd
COPY ./internal /build/internal

ARG CGO_ENABLED=0
ARG GOOS=linux
ARG BUILDSTR

# Build static binary with version information
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go build \
    -ldflags="-s -w -X 'main.buildString=${BUILDSTR}'" \
    -o calert ./cmd


FROM gcr.io/distroless/static-debian12:debug AS runtime

ARG CALERT_GID="999"
ARG CALERT_UID="999"

WORKDIR /app

COPY --from=builder --chown=${CALERT_UID}:${CALERT_GID} /build/calert /usr/local/bin/calert

COPY --chown=${CALERT_UID}:${CALERT_GID} static/ /app/static/
COPY --chown=${CALERT_UID}:${CALERT_GID} config.sample.toml /app/

USER ${CALERT_UID}:${CALERT_GID}

EXPOSE 6000

VOLUME /config

ENTRYPOINT ["calert"]
