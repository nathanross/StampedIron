echo "
deb http://ftp.us.debian.org/debian testing main contrib
deb http://ftp.debian.org/debian/ jessie-updates main contrib
deb http://security.debian.org/ jessie/updates main contrib
" > /etc/apt/sources.list

apt-get -y update
apt-get -y install squid3

#~8000MB cache
echo -e "cache_dir aufs /var/spool/squid3 8000 16 256\n
maximum_object_size 200MB\n
" >> /etc/squid3/squid.conf
service squid3 stop
killall squid3 
#squid has bug where service stop sometimes doesn't always end process.
squid3 -z #create cache directories
service squid3 start

# on host
#cat /usr/lib64/systemd/network/zz-default.network
# set IPForward=yes in the .network files explicitly now,
