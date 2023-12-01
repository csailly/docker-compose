https://medium.com/workleap/the-only-local-mongodb-replica-set-with-docker-compose-guide-youll-ever-need-2f0b74dd8384
https://developer.confluent.io/courses/security/hands-on-setting-up-encryption/

1. Create kafka certificates amd mode secrets to kafka/secrets

```shell
  ./create-kafka-certs.sh
```

2. Start

```shell
 docker compose up kafka mongodb-rs1 --wait --remove-orphans
```
