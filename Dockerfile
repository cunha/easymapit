# Using Python 3.7 for maximum compatibility with dependencies
FROM python:3.7-bullseye

VOLUME /data
WORKDIR /app

RUN apt-get update && apt-get install -y scamper
RUN pip install ip2as
RUN pip install bdrmapit

COPY retrieve_external/ retrieve_external/
RUN pip install -r retrieve_external/requirements.txt
RUN cd retrieve_external && python setup.py install

COPY entrypoint.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
