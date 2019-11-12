# docker-squid
containerized squid with domain whitelisting.

## Features
* squid v4.9 with openssl enabled
* domain whitelisting from environment variable
* ssl-bump splice on whitelist

## todo
* access log to stdout
* wire ssm squid.conf
* example ecs fargate deployment
* add dhparam key


## Usage

Startup the squid container
```bash
docker run -d \
  --restart=always \
  --name squid \
  -e SELFSIGNED_CA_ENABLED=true \
  -e DEFAULT_WHITELIST_ENABLED=true \
  -p 3128:3128 \
  garyellis/docker-squid

```

client exports proxy configuration.
```bash
export http_proxy=<squid-ip>:3128
export https_proxy=<squid-ip>:3128

curl -v -L https://github.com -o /dev/null
```
