include:
  - java.install

elastic-unlimit:
  file.managed:
    - name: /etc/security/limits.conf
    - source: salt://elasticsearch/files/limits.conf
  cmd.run:
    - name: ulimit -l unlimited
    - unless: ulimit -a |grep "max locked memory" |grep unlimited

elastic-repo:
  cmd.run: 
    - name: rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && . /etc/profile
    - unless: test -f /etc/yum.repos.d/elastic.repo
  file.managed:
    - name: /etc/yum.repos.d/elastic.repo
    - source: salt://elasticsearch/files/elastic.repo

elastic-service:
  file.managed:
    - name: /usr/lib/systemd/system/elasticsearch.service
    - source: salt://elasticsearch/files/elasticsearch.service
    - require:
      - pkg: elastic-install

vm.max_map_count:
  sysctl.present:
    - value: 262144

elastic-install:
  pkg.installed:
    - name: elasticsearch
    - require:
      - file: elastic-repo
  cmd.run:
    - name: systemctl daemon-reload
    - watch:
      - file: elastic-service
  service.running:
    - name: elasticsearch
    - enable: True
    - reload: True
    - require:
      - pkg: elastic-install
      - file: java-install
    - watch:
      - file: elastic-jvm
      - file: elastic-log

  file.managed:
    - name: /etc/elasticsearch/elasticsearch.yml
    - source: salt://elasticsearch/files/elasticsearch.yml
    - template: jinja
    - CLUSTER_NAME: elk
    - HOST_NAME: {{ grains['nodename'] }}
    - HOST_IP: {{ grains['ip4_interfaces']['ens33'] }}
    - PORT: 9200
    - HOST1: elk1
    - HOST2: elk2
    - HOST3: elk3
    - HOST4: elk4
    {% if (grains['nodename'] == 'elk1') or (grains['nodename'] == 'elk2') %}
    - RACK: hot
    {% elif (grains['nodename'] == 'elk3') or (grains['nodename'] == 'elk4') %}
    - RACK: warm
    {% endif %}
    - require:
      - pkg: elastic-install

elastic-jvm:
  file.managed:
    - name: /etc/elasticsearch/jvm.options
    - source:  salt://elasticsearch/files/jvm.options
    - require:
      - pkg: elastic-install

elastic-log:
  file.managed:
    - name: /etc/elasticsearch/log4j2.properties
    - source: salt://elasticsearch/files/log4j2.properties
    - require:
      - pkg: elastic-install
