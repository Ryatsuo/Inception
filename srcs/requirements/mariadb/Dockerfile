FROM debian:bookworm

RUN apt update && apt install -y \ 
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init_db.sh"]