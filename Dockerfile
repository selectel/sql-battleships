FROM postgres:12.4

ENV POSTGRES_HOST_AUTH_METHOD trust
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
	apt-get install -y --no-install-recommends apt-utils && \
	apt-get install -y supervisor && \
	mkdir /sql-battleships

COPY supervisord.conf /etc/supervisor/conf.d/supervisor.conf

COPY *.sql server-log-refresh.sh postgresql.conf /sql-battleships/

RUN cd /sql-battleships && cat logs.sql random.sql keyboard.sql game-field.sql battleships.sql > /docker-entrypoint-initdb.d/init.sql

EXPOSE 5432

ENTRYPOINT ["/usr/bin/supervisord"]

