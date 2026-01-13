FROM alpine:3.23

ENV LANG=en_US.UTF-8 \
    PG_MAJOR=18 \
    PGDATA=/var/lib/postgresql/data

RUN set -eux; \
    addgroup -g 70 -S postgres; \
    adduser -u 70 -S -D -G postgres -H -h /var/lib/postgresql -s /bin/sh postgres; \
    mkdir -p /var/lib/postgresql; \
    chown -R postgres:postgres /var/lib/postgresql

RUN set -eux; \
    apk add --no-cache \
        postgresql${PG_MAJOR} \
        postgresql${PG_MAJOR}-client \
        su-exec \
        tzdata \
    ; \
    # Remove unnecessary files
    rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /var/cache/apk/* \
    ; \
    # Verify installation
    postgres --version

# Create required directories
RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 3777 /var/run/postgresql \
    && mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 1777 "$PGDATA"

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

STOPSIGNAL SIGINT
EXPOSE 5432

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]