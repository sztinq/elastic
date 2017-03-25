/etc/profile:
  file.append:
    - text:
      - export HISTTIMEFORMAT="%F %T `whoami` "
      - export JAVA_HOME=/usr/java/jdk1.8.0_121
  cmd.run:
    - name: . /etc/profile
