echo "
deb http://ftp.us.debian.org/debian stable main contrib
deb http://ftp.debian.org/debian/ jessie-updates main contrib
deb http://security.debian.org/ jessie/updates main contrib
" > /etc/apt/sources.list

#give some time for the network to go up
sleep 10
apt-get -y update
apt-get -y install squid3

#~8000MB cache
echo -e "cache_dir aufs /var/spool/squid3 8000 16 256
maximum_object_size 200 MB
" >> /etc/squid3/squid.conf

sed -ri "s/http_access deny all/http_access allow localnet\nhttp_access deny all/g" /etc/squid3/squid.conf
sed -ri "s/^#acl localnet src 192.168/acl localnet src 192.168/g" /etc/squid3/squid.conf

service squid3 stop
squid3 -z #create cache directories
service squid3 start

# on host
#cat /usr/lib64/systemd/network/zz-default.network
# set IPForward=yes in the .network files explicitly now,
