# Manually run the below code before running post-inst.sh


./bootstrap.sh

 ./configure \
     --prefix=/opt/coirtx \
     --sysconfdir=/etc/coirtx \
     --localstatedir=/var \
     --enable-server \
     --enable-agent2 \
     --enable-webservice \
     --with-postgresql \
     --with-net-snmp \
     --with-libcurl \
     --with-openipmi \
     --with-libxml2 \
     --with-ssh2 \
     --with-openssl

make -j$(nproc)

sudo make install

make dbschema
