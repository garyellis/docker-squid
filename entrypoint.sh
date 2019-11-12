#!/bin/bash -e

export WHITELIST_FROM_ENV_ENABLED=${WHITELIST_FROM_ENV_ENABLED:-true}
export WHITELIST_DOMAIN_NAMES="${WHITELIST_DOMAIN_NAMES:-google.com,github.com}"

function makedirs(){
  mkdir -p /var/log/squid && chmod 777 /var/log/squid
  mkdir -p /var/spool/squid && chmod 777 /var/spool/squid
}

function selfsigned_ca(){
  if [ ! "${SELFSIGNED_CA_ENABLED}" == "true" ]; then
    return
  fi
  echo "creating selfsigned squid ca certificate"
  mkdir -p /etc/squid/ssl
  openssl req -x509 -new -newkey rsa:4096 -nodes -keyout /etc/squid/ssl/squid.pem -out /etc/squid/ssl/squid.pem -days 365 \
    -subj "/C=US/ST=Arizona/L=Scottsdale/O=EWSARCH/CN=squid"
}

function whitelist_from_env(){
  if [ ! "${WHITELIST_FROM_ENV_ENABLED}" == "true" ]; then
    return
  fi
  echo "creating /etc/squid/squid.allowed.sites.txt"
  cat <<EOF > /etc/squid/squid.allowed.sites.txt
$(echo ${WHITELIST_DOMAIN_NAMES}|sed 's/,/\n/g')
EOF

}

function aws_ssm_config(){
  if [ ! "${AWS_SSM_CONFIG_ENABLED}" == "true" ]; then
    return
  fi
  echo "squid.conf from ssm not yet implemented"
}

makedirs
selfsigned_ca
whitelist_from_env
aws_ssm_config

exec "$@"
