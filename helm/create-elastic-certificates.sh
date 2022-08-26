#!/bin/bash

ELASTICSEARCH_IMAGE="docker.elastic.co/elasticsearch/elasticsearch:7.17.3"
ELASTIC_PASSWORD="yourpassword"

sudo docker rm -f elastic-helm-charts-certs || true
rm -f elastic-certificates.p12 elastic-certificate.pem elastic-certificate.crt elastic-stack-ca.p12 || true
password=$(echo $ELASTIC_PASSWORD || echo $(sudo docker run --rm ${ELASTICSEARCH_IMAGE} /bin/sh -c "< /dev/urandomtr -cd '[:alnum:]' | head -c20")) && \
sudo docker run --name elastic-helm-charts-certs -i -w /app \
    ${ELASTICSEARCH_IMAGE} \
    /bin/sh -c " \
        elasticsearch-certutil ca --out /app/elastic-stack-ca.p12 --pass '' && \
        elasticsearch-certutil cert --name elasticsearch-master.logging.svc.cluster.local --dns elasticsearch-master.logging.svc.cluster.local --ca /app/elastic-stack-ca.p12 --pass '' --ca-pass '' --out /app/elastic-certificates.p12" && \
sudo docker cp elastic-helm-charts-certs:/app/elastic-certificates.p12 ./ && \
sudo docker rm -f elastic-helm-charts-certs && \
sudo openssl pkcs12 -nodes -passin pass:'' -in elastic-certificates.p12 -out elastic-certificate.pem && \
sudo openssl x509 -outform der -in elastic-certificate.pem -out elastic-certificate.crt && \
sudo chown ec2-user:ec2-user elastic-certificates.p12 && \
sudo chown ec2-user:ec2-user elastic-certificate.pem && \
sudo chown ec2-user:ec2-user elastic-certificate.crt && \
kubectl create secret generic elastic-certificates --from-file=elastic-certificates.p12 -n logging && \
kubectl create secret generic elastic-certificate-pem --from-file=elastic-certificate.pem -n logging && \
kubectl create secret generic elastic-certificate-crt --from-file=elastic-certificate.crt -n logging && \
kubectl create secret generic elastic-credentials --from-literal=password=$password --from-literal=username=elastic -n logging # && \
# rm -f elastic-certificates.p12 elastic-certificate.pem elastic-certificate.crt elastic-stack-ca.p12
