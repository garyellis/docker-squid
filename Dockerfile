from ubuntu:18.04


RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    openssl \
    build-essential \
    libssl-dev \
    curl

ENV MAJOR_VERSION=v4
ENV VERSION=4.9
RUN cd /tmp && \
    curl -s http://www.squid-cache.org/Versions/$MAJOR_VERSION/squid-${VERSION}.tar.gz | tar xzvf - && \
    cd squid-${VERSION} && \
    ./configure \
      --prefix=/usr \
      --localstatedir=/var \
      --libexecdir=${prefix}/lib/squid \
      --datadir=${prefix}/share/squid \
      --sysconfdir=/etc/squid \
      --with-logdir=/var/log/squid \
      --with-pidfile=/var/run/squid.pid \
      --enable-icap-client \
      --with-openssl \
      --enable-ssl-crtd \
      --enable-auth \
      --enable-basic-auth-helpers="NCSA" && \
    make all && \
    make install && \
    rm -fr /tmp/squid-${VERSION}

EXPOSE 3128

COPY ./squid.conf /etc/squid/squid.conf
COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["squid", "-f", "/etc/squid/squid.conf", "-NYCd","1"]
