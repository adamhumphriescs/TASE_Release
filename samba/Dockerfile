FROM tase

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && apt-get -y install pkg-config git make gcc g++ python3 python3-dev zlib1g zlib1g-dev liblmdb0 liblmdb-dev flex bison libgnutls30 libgnutls28-dev libarchive13 libarchive-dev libacl1-dev libldap2-dev krb5-kdc krb5-admin-server krb5-config libkrb5-3 libkrb5-dev nano gdb less

RUN cpan Parse::Yapp::Driver

RUN git clone https://github.com/samba-team/samba.git && cd samba && git checkout 67294a23b97e3fae3c20861a8313f860b89a2859

#RUN cd samba && ./configure --without-pie --without-ad-dc --without-gpgme --without-json --without-pam --without-relro --with-shared-modules='!vfs_snapper' && make bin/smbclient
