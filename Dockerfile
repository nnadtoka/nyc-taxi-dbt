FROM postgres:16-bullseye
COPY database /docker-entrypoint-initdb.d/
COPY data /data
ENV POSTGRES_PASSWORD=taxi
