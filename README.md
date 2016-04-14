# Mysql-Service-Broker

Simple CloudFoundry service broker for MySQL based on [service-broker-api](https://github.com/cskksc/service-broker-api).

# Usage

The mysql broker needs a user with the following permission:
```SQL
GRANT ALL ON `%`.* TO '{broker_admin}'@'%'
```
