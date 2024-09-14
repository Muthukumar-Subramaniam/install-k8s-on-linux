#!/bin/bash
#This script downloads conntrack-tools from source rpm and renames it to conntrack and builds RPM as conntrack
#Run this from SuSE Linux Testing VM
zypper install -y rpm-build
mkdir /root/conntrack 
wget -P /root/conntrack/ https://ftp.lysator.liu.se/pub/opensuse/source/distribution/leap/15.5/repo/oss/src/conntrack-tools-1.4.5-1.46.src.rpm
rpm -i /root/conntrack/conntrack-tools-1.4.5-1.46.src.rpm
tar -C /usr/src/packages/SOURCES/ -xjvf /usr/src/packages/SOURCES/conntrack-tools-1.4.5.tar.bz2
mv /usr/src/packages/SOURCES/conntrack-tools-1.4.5 /usr/src/packages/SOURCES/conntrack-1.4.5

rm -rf /usr/src/packages/SOURCES/conntrack-tools-1.4.5*

find /usr/src/packages/SOURCES/ -type f -name "conntrack-tools*" >>/root/conntrack/rename-files-and-dir
find /usr/src/packages/SOURCES/ -type d -name "conntrack-tools*" >>/root/conntrack/rename-files-and-dir

for v_files_and_dir in $(cat /root/conntrack/rename-files-and-dir)
do
	mv $v_files_and_dir $(echo $v_files_and_dir | sed "s/conntrack-tools/conntrack/g")
done

find /usr/src/packages/SOURCES/ -type f -exec sed -i "s/conntrack-tools/conntrack/g" {} \;

tar -C /usr/src/packages/SOURCES/ -cjvf /usr/src/packages/SOURCES/conntrack-1.4.5.tar.bz2 conntrack-1.4.5

mv /usr/src/packages/SPECS/conntrack-tools.spec /usr/src/packages/SPECS/conntrack.spec

sed -i "s/conntrack-tools/conntrack/g" /usr/src/packages/SPECS/conntrack.spec

zypper install -y automake flex libtool libmnl-devel libnetfilter_conntrack-devel libnetfilter_cthelper-devel libnetfilter_cttimeout-devel libnetfilter_queue-devel libnfnetlink-devel ghc-libsystemd-journal-devel libtirpc-devel

rpmbuild -bb /usr/src/packages/SPECS/conntrack.spec

rsync -avPh /usr/src/packages/RPMS/x86_64/conntrack-1.4.5-1.46.x86_64.rpm  /root/conntrack/

ls -l /root/conntrack/conntrack-1.4.5-1.46.x86_64.rpm
