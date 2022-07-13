FROM ubuntu:20.04

VOLUME ["/app"]

RUN apt update -y \
  && apt install -y git make python3 lua5.3

WORKDIR /app

CMD ["make", "re"]