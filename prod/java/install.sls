java-install:
  file.managed:
    - name: /usr/local/src/jdk-8u121-linux-x64.rpm
    - source: salt://java/files/jdk-8u121-linux-x64.rpm
  cmd.run:
    - name: rpm -ivh /usr/local/src/jdk-8u121-linux-x64.rpm
    - unless: test -d /usr/java/jdk1.8.0_121
