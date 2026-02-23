FROM railwayapp/pgbouncer:latest

USER root
COPY json-logger.sh /json-logger.sh
COPY entrypoint-json.sh /entrypoint-json.sh
RUN chmod +x /json-logger.sh /entrypoint-json.sh
USER 1001

ENTRYPOINT ["/entrypoint-json.sh"]
CMD []
