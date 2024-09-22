#!/bin/bash
public_dns=$1
token=$2
#�µ�ip
public_ip=$(curl -s "cip.cc")
public_ip=${public_ip##*/}
#�ɵ�ip
current_ip=$(dig +short $public_dns)
echo "old_ip" $current_ip
echo "new_ip" $public_ip
#�Ƚ��Ƿ��б仯
if [ $current_ip == $public_ip ]; then
  echo $(date) "uniformity"
  exit 1
else
     #����ip
  Results=$(curl -s "http://ipv4.dynv6.com/api/update?hostname=$public_dns&ipv4=$public_ip&token=$token")
     echo "Results:" $Results 
  echo $(date) "success"
fi