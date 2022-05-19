FROM tase

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && apt-get -y install python2.7 python2.7-dev pkg-config git make gcc g++ python3 zlib1g zlib1g-dev liblmdb0 liblmdb-dev flex bison libgnutls30 libgnutls28-dev libarchive13 libarchive-dev libacl1-dev libldap2-dev krb5-kdc krb5-admin-server krb5-config libkrb5-3 libkrb5-dev nano gdb less libpopt0 libpopt-dev libtdb1 libtdb-dev libtalloc2 libtalloc-dev libtevent0 libtevent-dev && ln -s /usr/bin/python2.7 /usr/bin/python
#python3-dev

RUN yes | perl -MCPAN -e 'install Parse::Yapp::Driver'

RUN git clone https://github.com/samba-team/samba.git && cd samba && git checkout samba-4.5.4

RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && python2.7 get-pip.py
#git checkout 67294a23b97e3fae3c20861a8313f860b89a2859

RUN pip install pyrpc


#RUN cd samba && ./configure --without-pie --without-ad-dc --without-gpgme --without-json --without-pam --without-relro --with-shared-modules='!vfs_snapper' && make bin/smbclient
