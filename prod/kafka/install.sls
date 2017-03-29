kafka-source-install:
  file.managed:
    - name: /usr/local/src/kafka_2.12-0.10.2.0.tgz
    - source: salt://kafka/files/kafka_2.12-0.10.2.0.tgz
  cmd.run:
    - name: cd /usr/local/src && tar zxf kafka_2.12-0.10.2.0.tgz -C /usr/local && ln -sv /usr/local/kafka_2.12-0.10.2.0 /usr/local/kafka
    - unless: test -d /usr/local/kafka
    - require:
      - file: kafka-source-install

kafka-init:
  file.managed:
    - name: /usr/local/kafka/config/server.properties
    - source: salt://kafka/files/server.properties
    - template: jinja
    {% if (grains['nodename'] == 'elk2') %}
    - BROKER_ID: 2
    {% elif (grains['nodename'] == 'elk3') %}
    - BROKER_ID: 3
    {% else %}
    - BROKER_ID: 4
    {% endif %}  
    - ZK1: 192.168.29.129
    - ZK2: 192.168.29.130
    - ZK3: 192.168.29.131
    - require:
      - cmd: kafka-source-install

zookeeper-init:
  file.managed:
    - name: /usr/local/kafka/config/zookeeper.properties
    - source: salt://kafka/files/zookeeper.properties
    - template: jinja
    - S1_IP: 192.168.29.129
    - S2_IP: 192.168.29.130
    - S3_IP: 192.168.29.131
    - require:
       - cmd: kafka-source-install

zookeeper-myid:
  cmd.run:
    - name: mkdir -p /data/zookeeper
    - unless: test -d /data/zookeeper
  file.managed:
    - name: /data/zookeeper/myid
    - source: salt://kafka/files/myid
    - template: jinja
    {% if (grains['nodename'] == 'elk2') %}
    - ZK_ID: 2
    {% elif (grains['nodename'] == 'elk3') %}
    - ZK_ID: 3
    {% else %}
    - ZK_ID: 4
    {% endif %}
    - require:
       - cmd: kafka-source-install
       - cmd: zookeeper-myid
#zookeeper-start:
#  cmd.run:
#    - name: /usr/local/kafka/bin/zookeeper-server-start.sh /usr/local/kafka/config/zookeeper.properties &
#    - unless: ps -ef | grep zookeeper | grep -v grep
#kafka-start:
#  cmd.run:
#    - name: /usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
#    - unless: ps -ef | grep kafka | grep -v grep
#    - require:
#      - cmd: zookeeper-start

zookeeper-service:
  file.managed:
    - name: /usr/lib/systemd/system/zookeeper.service
    - source: salt://kafka/files/zookeeper.service
  service.running:
    - name: zookeeper
    - enable: True
    - reload: True
    - require:
      - cmd: zookeeper-myid
    - watch:
      - file: /usr/lib/systemd/system/zookeeper.service

kafka-service:
  file.managed:
    - name: /usr/lib/systemd/system/kafka.service
    - source: salt://kafka/files/kafka.service
  service.running:
    - name: kafka
    - enable: True
    - reload: True
    - require:
      - service: zookeeper-service
    - watch:
      - file: /usr/lib/systemd/system/kafka.service

