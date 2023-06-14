#!/bin/bash
set -e # terminate as soon as a command fails
#set -x # print command, helpful for debugging

## all ASNs that will get access
declare -a ASNs=("AS3320" # deutsche telekom
    "AS24940"             # hetzner
    "AS20810"             # netcom kassel
)

## remove all existing DNS rules
## in reverse order so the numbers remains valid
dns_rules_str=$(ufw status numbered | grep DNS | tr -d [ | tr -d ] | awk '{print $1}' | tac)
dns_rules=($dns_rules_str)
for rule in "${dns_rules[@]}"; do
    yes | ufw delete $rule
done

## allow acess to port 53 for the ASNs
for ASN in "${ASNs[@]}"; do
    routes_str=$(whois -i origin "$ASN" -K | grep route | awk '{print $2}')
    routes=($routes_str)
    for route in "${routes[@]}"; do
        ufw allow from $route to any port 53 comment 'DNS'
    done
done

## allow access from wg0
ufw allow in on wg0 to any port 53 comment 'DNS'

## deny access to port 53 for everyone else
ufw deny from any to any port 53 comment 'DNS'
