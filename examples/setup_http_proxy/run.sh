echo 'http_proxy=$PROXY_ADDR' >> ~/.wgetrc
[ -e /etc/apt ] && echo "Acquire::http::Proxy \"http://${PROXY_ADDR}\"" >> /etc/apt/apt.conf
