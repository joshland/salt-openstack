{% set postgresql = salt['openstack_utils.postgresql']() %}


postgresql_mgmt_account:
  postgres_user.present:
    - name:        {{ postgresql['root_user'] }}
    - password:    {{ postgresql['root_password'] }}
    ## role-related flags
    - createdb:    true
    - createroles: true
    - superuser:   true
    ## System Username/Password for access.
    - user:        "postgres"


{% for database in postgresql['databases'] %}
postgresql_{{ database }}_account:
  postgres_user.present:
    - name:        {{ postgresql['databases'][database]['username'] }}
    - password:    {{ postgresql['databases'][database]['password'] }}
    ## role-related flags
    - createdb:    false
    - createroles: false
    - superuser:   false
    ## System Username/Password for access.  
    - db_user:     {{ postgresql['root_user'] }}
    - db_password: {{ postgresql['root_password'] }}


postgresql_{{ database }}_db:
  postgres_database.present:
    - name:  {{ postgresql['databases'][database]['db_name'] }}
    - owner: {{ postgresql['databases'][database]['username'] }}
    - encoding: 'utf8'
    ## System Username/Password for access.  
    - db_user:     {{ postgresql['root_user'] }}
    - db_password: {{ postgresql['root_password'] }}
    - require:
      - postgresql_database: postgresql_{{ database }}_account
{% endfor %}
