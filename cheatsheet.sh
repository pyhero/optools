#!/usr/bin/env bash

# mount disk by uuid
sudo lsblk -f -s -d | sed '1d' | sort -k2 -n | awk '{print "UUID="$3"\t"$NF"\t"$2"\t"defaults"\t0 0"}' >> /etc/fstab
