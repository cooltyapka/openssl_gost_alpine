# Docker image with Alpine linux 3.21, OpenSSL 1.1.1w, GOST engine 1.1.1

Based on https://github.com/rnixik/docker-openssl-gost


## Examples

To generate private key and certificate request with GOST

```
openssl req -newkey gost2012_256 -pkeyopt paramset:A -passout pass:123456 -extensions usr_cert -keyout private_key.pem
```
