FROM rust:bookworm as build

ARG BRANCH=master
ARG FEATURES=pulseaudio_backend

WORKDIR /spotifyd

RUN apt-get -y update && apt-get install -y \
    libasound2-dev \
    libpulse-dev

RUN git clone --branch=${BRANCH} https://github.com/Spotifyd/spotifyd.git . 
RUN cargo build --release --features ${FEATURES}

FROM debian:bookworm-slim

RUN apt-get -y update && apt-get install -y \
    libasound2 \
    libpulse0 \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r spotify && \
    useradd -rmg spotify -G audio spotify

USER spotify
WORKDIR /home/spotify

COPY spotifyd.conf ~/.config/spotifyd
COPY --from=build /spotifyd/target/release/spotifyd /usr/bin/

EXPOSE 59071

CMD /usr/bin/spotifyd --no-daemon
