FROM debian:bookworm

RUN apt update && apt install -y \
	php-fpm \
	php-mysql \
	php-cli \
	curl \
	ca-certificates \
	netcat-openbsd \
	&& rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -sSLo /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

# Copy config and setup script
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]
