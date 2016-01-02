{% set postgresql = salt['openstack_utils.postgresql']() %}


{% for database in postgresql['databases'] %}
postgresql_{{ database }}_db:
  postgres_database.present:
    - name: {{ postgresql['databases'][database]['db_name'] }}
    - character_set: 'utf8'
    - connection_user: root
    - connection_pass: {{ postgresql['root_password'] }}
    - connection_charset: utf8


{% for host in ['localhost', '%'] %}
postgresql_{{ database }}_{{ host }}_account:
  postgres_user.present:
    - db_name: {{ postgresql['databases'][database]['username'] }}
    - db_password: {{ postgresql['databases'][database]['password'] }}
    - require:
      - postgresql_database: postgresql_{{ database }}_db
{% endfor %}


{% for host in ['localhost', '%'] %}
postgresql_{{ database }}_{{ host }}_grants:
  postgres_grants.present:
    - grant: all
    - name: "{{ postgresql['databases'][database]['db_name'] }}.*"
    - db_user: {{ postgresql['databases'][database]['username'] }}
    - db_password: {{ postgresql['databases'][database]['password'] }}
    - require:
      - postgresql_user: postgresql_{{ database }}_{{ host }}_account
  {% endfor %}
{% endfor %}
