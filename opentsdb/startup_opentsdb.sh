#!/bin/bash
export TSDB_VERSION=2.3.1
export HBASE_VERSION=1.4.4
export GNUPLOT_VERSION=5.2.4
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:/usr/lib/jvm/java-1.8.0-openjdk/bin/
export ALPINE_PACKAGES="autoconf libtool vim curl telnet unzip rsyslog bash java-1.8.0-openjdk java-1.8.0-openjdk-devel make wget libgd libpng libjpeg libwebp libjpeg-turbo cairo pango lua"
export BUILD_PACKAGES="build-base autoconf automake git python cairo-dev pango-dev gd-dev lua-dev readline-dev libpng-dev libjpeg-turbo-dev libwebp-dev"
export HBASE_OPTS="-XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
export JVMARGS="-XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -enableassertions -enablesystemassertions"

# Add the base packages we'll needs
sudo yum -y install ${ALPINE_PACKAGES}
sudo mkdir -p /opt/opentsdb/

cd /opt/opentsdb
sudo wget --no-check-certificate -O v${TSDB_VERSION}.zip https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip
sudo unzip v${TSDB_VERSION}.zip
sudo rm v${TSDB_VERSION}.zip
echo "tsd.http.request.enable_chunked = true" >> /opt/opentsdb/opentsdb-${TSDB_VERSION}/src/opentsdb.conf
echo "tsd.http.request.max_chunk = 1000000" >> /opt/opentsdb/opentsdb-${TSDB_VERSION}/src/opentsdb.conf
cd /opt/opentsdb/opentsdb-${TSDB_VERSION}
./build.sh
cp build-aux/install-sh build/build-aux
cd build
make install
cd / 
sudo rm -rf /opt/opentsdb/opentsdb-${TSDB_VERSION}

# wget --no-check-certificate \
#     -O v${TSDB_VERSION}.zip \
#     https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip \
#   && unzip v${TSDB_VERSION}.zip \
#   && rm v${TSDB_VERSION}.zip \
#   && cd /opt/opentsdb/opentsdb-${TSDB_VERSION} \
#   && echo "tsd.http.request.enable_chunked = true" >> src/opentsdb.conf \
#   && echo "tsd.http.request.max_chunk = 1000000" >> src/opentsdb.conf \
#   && ./build.sh \
#   && cp build-aux/install-sh build/build-aux \
#   && cd build \
#   && make install \
#   && cd / \
#   && rm -rf /opt/opentsdb/opentsdb-${TSDB_VERSION}


# cd /tmp
# sudo wget https://datapacket.dl.sourceforge.net/project/gnuplot/gnuplot/${GNUPLOT_VERSION}/gnuplot-${GNUPLOT_VERSION}.tar.gz
# tar xzf gnuplot-${GNUPLOT_VERSION}.tar.gz
# cd gnuplot-${GNUPLOT_VERSION}
# ./configure
# make install
# cd /tmp
# sudo rm -rf /tmp/gnuplot-${GNUPLOT_VERSION}
# sudo rm /tmp/gnuplot-${GNUPLOT_VERSION}.tar.gz

cd /tmp && \
  wget https://datapacket.dl.sourceforge.net/project/gnuplot/gnuplot/${GNUPLOT_VERSION}/gnuplot-${GNUPLOT_VERSION}.tar.gz && \
  tar xzf gnuplot-${GNUPLOT_VERSION}.tar.gz && \
  cd gnuplot-${GNUPLOT_VERSION} && \
  ./configure && \
  make install && \
  cd /tmp && yes | rm -rf /tmp/gnuplot-${GNUPLOT_VERSION} && rm /tmp/gnuplot-${GNUPLOT_VERSION}.tar.gz


#Install HBase and scripts
sudo mkdir -p /data/hbase /root/.profile.d /opt/downloads /opt/hbase /opt/bin
cd /opt/downloads
wget -O hbase-${HBASE_VERSION}.bin.tar.gz http://archive.apache.org/dist/hbase/${HBASE_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz
tar xzvf hbase-${HBASE_VERSION}.bin.tar.gz
sudo mv hbase-${HBASE_VERSION} hbase
sudo mv hbase /opt/
sudo rm -r /opt/hbase/docs
sudo rm hbase-${HBASE_VERSION}.bin.tar.gz

# Add misc startup files
ln -s /usr/local/share/opentsdb/etc/opentsdb /etc/opentsdb \
    && rm -rf /etc/opentsdb/opentsdb.conf \
    && sudo mkdir /opentsdb-plugins
cd /home/gce-pttep-internal-dev/opentsdb/
yes | cp -rf files/opentsdb.conf /etc/opentsdb/opentsdb.conf.sample
yes | cp -rf files/hbase-site.xml /opt/hbase/conf/hbase-site.xml.sample
yes | cp -rf files/start_opentsdb.sh /opt/bin/
yes | cp -rf files/create_tsdb_tables.sh /opt/bin/
yes | cp -rf files/start_hbase.sh /opt/bin/
yes | cp -rf jar/target/ /opentsdb-plugins
sudo mkdir -p /opt/opentsdb/script/
yes | cp -rf files/start_service.sh /opt/opentsdb/script/

# Fix export variables=in installed scripts
for i in /opt/bin/start_hbase.sh /opt/bin/start_opentsdb.sh /opt/bin/create_tsdb_tables.sh; \
  do \
      sed -i "s#::JAVA_HOME::#$JAVA_HOME#g; s#::PATH::#$PATH#g; s#::TSDB_VERSION::#$TSDB_VERSION#g;" $i; \
  done

echo "export HBASE_OPTS=\"${HBASE_OPTS}\"" >> /opt/hbase/conf/hbase-export.sh


# install grafana
wget https://dl.grafana.com/oss/release/grafana-6.2.5-1.x86_64.rpm 
sudo yum -y localinstall grafana-6.2.5-1.x86_64.rpm
systemctl daemon-reload
systemctl start grafana-server

sudo chmod +x /opt/opentsdb/script/start_service.sh
nohup /opt/opentsdb/script/start_service.sh > opentsdb.log 2>&1 &