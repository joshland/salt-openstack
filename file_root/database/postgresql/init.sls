{% set postgresql = salt['openstack_utils.postgresql']() %}
{% set openstack_parameters = salt['openstack_utils.openstack_parameters']() %}


{% for pkg in postgresql['packages'] %}
postgresql_{{ pkg }}_install:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}


pg_hba_conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - name: {{ postgresql['conf']['hba'] }}
      # fixme: Add loop for all openstack hosts
    - contents: |
        local   all             postgres                                peer
        local   all             all                                     peer
        host    all             all             127.0.0.1/32            md5
        host    all             all             ::1/128                 md5
        host    all             all             10.0.0.0/8              md5
    - require: 
{% for pkg in postgresql['packages'] %}
      - pkg: postgresql_{{ pkg }}_install
{% endfor %}

pg_ident_conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - name: {{ postgresql['conf']['ident'] }}
      # fixme: Add loop for all openstack hosts
    - contents: |
        # MAPNAME       SYSTEM-USERNAME PG-USERNAME
        root_as_others  root            postgres
    - require: 
{% for pkg in postgresql['packages'] %}
      - pkg: postgresql_{{ pkg }}_install
{% endfor %}


postgresql_conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - name: {{ postgresql['conf']['postgresql'] }}
    - contents: |
        data_directory = '/var/lib/postgresql/9.3/main'
        hba_file = '/etc/postgresql/9.3/main/pg_hba.conf'
        ident_file = '/etc/postgresql/9.3/main/pg_ident.conf'
        external_pid_file = '/var/run/postgresql/9.3-main.pid'
        listen_addresses = '{{ openstack_parameters['controller_ip'] }}'
        port = 5432
        max_connections = 200
        unix_socket_directories = '/var/run/postgresql'
        ssl = true
        ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
        ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
        shared_buffers = 128MB
        log_line_prefix = '%t '
        log_timezone = 'localtime'
        autovacuum = on
        autovacuum_max_workers = 3
        datestyle = 'iso, mdy'
        timezone = 'localtime'
        lc_messages = 'en_US.UTF-8'
        lc_monetary = 'en_US.UTF-8'
        lc_numeric = 'en_US.UTF-8'
        lc_time = 'en_US.UTF-8'
        default_text_search_config = 'pg_catalog.english'
    - require: 
{% for pkg in postgresql['packages'] %}
      - pkg: postgresql_{{ pkg }}_install
{% endfor %}


postgresql_service_running:
  service.running:
    - enable: True
    - name: {{ postgresql['services']['postgresql'] }}
    - watch: 
      - file: postgresql_conf


postgresql_secure_installation_script:
  file.managed:
    - user: root
    - group: root
    - mode: 400
    - name: "/tmp/postgresql-secure-installation.sh"
    - contents: |
        #!/bin/bash
        #postgresql -u root -p"{{ postgresql['root_password'] }}" -e "" &> /dev/null
        #if [ $? -eq 0 ]; then
        #    echo "MySQL root password was already set."
        #else
        #    postgresql -u root -e "" &> /dev/null
        #    if [ $? -eq 0 ]; then
        #        postgresqladmin -u root password "{{ postgresql['root_password'] }}"
        #        echo "MySQL root password has been successfully set."
        #    else
        #        echo "ERROR: Cannot change MySQL root password." >&2
        #        exit 1
        #    fi
        #fi
        #postgresql -u root -p"{{ postgresql['root_password'] }}" -e "UPDATE postgresql.user SET Password=PASSWORD('{{ postgresql['root_password'] }}') WHERE User='root';"
        #postgresql -u root -p"{{ postgresql['root_password'] }}" -e "DELETE FROM postgresql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
        #postgresql -u root -p"{{ postgresql['root_password'] }}" -e "DELETE FROM postgresql.user WHERE User='';"
        #postgresql -u root -p"{{ postgresql['root_password'] }}" -e "use test;" &> /dev/null
        #if [ $? -eq 0 ]; then
        #    postgresql -u root -p"{{ postgresql['root_password'] }}" -e "DROP DATABASE test;"
        #fi
        #postgresql -u root -p"{{ postgresql['root_password'] }}" -e "FLUSH PRIVILEGES;"
        #echo "Finished MySQL secure installation."
        exit 0
    - require:
      - service: postgresql_service_running


postgresql_secure_installation_run:
  cmd:
    - run
    - name: "bash /tmp/postgresql-secure-installation.sh"
    - require:
      - file: postgresql_secure_installation_script


postgresql_secure_installation_script_delete:
  file:
    - absent
    - name: "/tmp/postgresql-secure-installation.sh"
