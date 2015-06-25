echo "http_proxy=$PROXY_ADDR" >> ~/.wgetrc
# you generally would want the ip included in the seedfile to begin with.
# todo, make idempotent so this works to add it in cases where its not added
# + causse no problems if it is
#if [ -e /etc/apt ]; then
#    addr=$PROXY_SOCKET
#    if ! [[ $addr =~ ^http:\/\/ ]]; then
#        addr="http://$addr"
#    fi
#    echo "Acquire::http::Proxy \"http://${addr}\"" >> /etc/apt/apt.conf
#fi
