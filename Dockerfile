FROM python:3.13.0a4-alpine3.19

RUN pip install docker pymongo==4.6.2 backoff

RUN mkdir /src
WORKDIR /src

COPY src/db-replica_ctrl.py /src/db-replica_ctrl.py