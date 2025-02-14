# Docker image with Alpine linux 3.21, OpenSSL 3.4.1, GOST engine

Based on https://github.com/rnixik/docker-openssl-gost


## Examples

To generate private key and certificate request with GOST

```
openssl req -newkey gost2012_256 -pkeyopt paramset:A -passout pass:123456 -keyout private_key.pem
```
