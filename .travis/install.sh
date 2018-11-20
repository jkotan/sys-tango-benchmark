#!/usr/bin/env bash

# workaround for incomatibility of default ubuntu 16.04 and tango configuration
if [ $1 = "ubuntu16.04" ]; then
    docker exec -it --user root s2i sed -i "s/\[mysqld\]/\[mysqld\]\nsql_mode = NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION/g" /etc/mysql/mysql.conf.d/mysqld.cnf
fi

echo "restart mysql"
if [ $1 = "debian9" ]; then
    # workaround for a bug in debian9, i.e. starting mysql hangs
    docker exec -it --user root s2i service mysql stop
    docker exec -it --user root s2i /bin/sh -c '$(service mysql start &) && sleep 30'
else
    docker exec -it --user root s2i service mysql restart
fi

docker exec -it --user root s2i /bin/sh -c 'export DEBIAN_FRONTEND=noninteractive; apt-get -qq update; apt-get -qq install -y tango-db tango-common; sleep 10'
if [ $? -ne "0" ]
then
    exit -1
fi
echo "install tango servers"
docker exec -it --user root s2i /bin/sh -c 'export DEBIAN_FRONTEND=noninteractive;  apt-get -qq update; apt-get -qq install -y tango-starter tango-test liblog4j1.2-java'
if [ $? -ne "0" ]
then
    exit -1
fi

docker exec -it --user root s2i service tango-db restart
docker exec -it --user root s2i service tango-starter restart

if [ $2 = "2" ]; then
    echo "install python-pytango"
    docker exec -it --user root s2i /bin/sh -c 'export DEBIAN_FRONTEND=noninteractive; apt-get -qq update; apt-get -qq install -y   python-pytango python-tz'
else
    echo "install python3-pytango"
    docker exec -it --user root s2i /bin/sh -c 'export DEBIAN_FRONTEND=noninteractive; apt-get -qq update; apt-get -qq install -y   python3-pytango python3-tz'
fi
if [ $? -ne "0" ]
then
    exit -1
fi

if [ $2 = "2" ]; then
    echo "install PyBenchmarkTarget"
    docker exec -it --user root s2i /bin/sh -c 'cd ds/PyBenchmarkTarget; python setup.py -q install'
else
    echo "install PyBenchmarkTarget"
    docker exec -it --user root s2i /bin/sh -c 'cd ds/PyBenchmarkTarget; python3 setup.py -q install'
fi
if [ $? -ne "0" ]
then
    exit -1
fi