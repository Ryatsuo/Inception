FROM debian:bookworm

RUN apt update && apt install -y \
	nginx \
	openssl \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Copy config template and setup script
COPY conf/wordpress.conf.template /etc/nginx/conf.d/wordpress.conf.template
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/setup.sh"]
