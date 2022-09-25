FROM golang:1-bullseye as build

RUN mkdir /build
ADD go.mod go.sum /build/
RUN cd /build && go mod download

ADD *.go /build/
RUN cd /build && go build -o /app


FROM debian:bullseye-slim
ARG CHROMIUM_REV
RUN apt update &&\
    apt install -y --no-install-recommends\
        libglib2.0-0 libnss3\
        libatk1.0-0 libatk-bridge2.0-0\
        libcups2\
        libxcomposite1\
        libxdamage1\
        libxext6\
        libxfixes3\
        libxrandr2\
        libdrm2\
        expat\
        libxkbcommon0\
        libpango-1.0-0\
        libcairo2\
        libasound2\
        libgbm1\
        &&\
    apt clean
ADD chrome-linux-$CHROMIUM_REV.tar.gz /opt/
COPY --from=build /app /app
ENTRYPOINT ["/app"]
