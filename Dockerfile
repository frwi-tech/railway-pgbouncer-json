FROM railwayapp/pgbouncer:latest

USER root
COPY json-logger.sh /json-logger.sh
COPY run-json.sh /opt/bitnami/scripts/pgbouncer/run-json.sh
RUN chmod +x /json-logger.sh /opt/bitnami/scripts/pgbouncer/run-json.sh
USER 1001

CMD ["/opt/bitnami/scripts/pgbouncer/run-json.sh"]
