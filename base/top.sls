base: 
  '*':
    - init.env_init

prod:
  '*':
    - elasticsearch.install
