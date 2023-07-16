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
    pulseaudio \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -rg 1000 spotify && \
    useradd -rmu 1000 -g spotify -G audio spotify

USER spotify
WORKDIR /home/spotify

COPY --chown=spotify:spotify ./spotifyd.conf ./.config/spotifyd/spotifyd.conf
COPY ./pulse-client.conf /etc/pulse/client.conf
COPY --from=build /spotifyd/target/release/spotifyd /usr/bin/

EXPOSE 59071

CMD /usr/bin/spotifyd --no-daemon
