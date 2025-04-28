#!/bin/bash

# Variables
DOMAIN="internal.example.com"
HOSTS_FILE="/etc/hosts"
TMP_FILE="/tmp/dns_check.tmp"

# Functions
function check_dns() {
    echo " Checking DNS resolution for $DOMAIN..."
    dig $DOMAIN +short > $TMP_FILE
    if [[ -s $TMP_FILE ]]; then
        IP=$(cat $TMP_FILE)
        echo " Resolved IP: $IP"
    else
        echo " DNS Resolution failed for $DOMAIN."
        IP=""
    fi
}

function check_service_ports() {
    if [[ -n "$IP" ]]; then
        echo " Checking port 80 (HTTP)..."
        nc -zv $IP 80 2>&1
        echo " Checking port 443 (HTTPS)..."
        nc -zv $IP 443 2>&1
    else
        echo " Skipping port check because IP is missing."
    fi
}

function add_hosts_entry() {
    if [[ -n "$IP" ]]; then
        if grep -q "$DOMAIN" $HOSTS_FILE; then
            echo "ℹ Entry for $DOMAIN already exists in $HOSTS_FILE"
        else
            echo " Adding $DOMAIN to $HOSTS_FILE"
            echo "$IP $DOMAIN" | sudo tee -a $HOSTS_FILE
            echo " Added successfully!"
        fi
    fi
}

# Main Execution
echo "==============================="
echo " Connectivity Check for $DOMAIN"
echo "==============================="

check_dns
check_service_ports

read -p " Do you want to add $DOMAIN to /etc/hosts? (y/n): " choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    add_hosts_entry
else
    echo " Skipping hosts file modification."
fi

# Cleanup
rm -f $TMP_FILE
echo " Done."

