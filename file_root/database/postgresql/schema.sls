{% set postgresql = salt['openstack_utils.postgresql']() %}


{% for database in postgresql['databases'] %}
postgresql_{{ database }}_db:
  postgresql_database.present:
    - name: {{ postgresql['databases'][database]['db_name'] }}
    - character_set: 'utf8'
    - connection_user: root
    - connection_pass: {{ postgresql['root_password'] }}
    - connection_charset: utf8


  {% for host in ['localhost', '%'] %}
postgresql_{{ database }}_{{ host }}_account:
  postgresql_user.present:
    - name: {{ postgresql['databases'][database]['username'] }}
    - password: {{ postgresql['databases'][database]['password'] }}
    - host: "{{ host }}"
    - connection_user: root
    - connection_pass: {{ postgresql['root_password'] }}
    - connection_charset: utf8
    - require:
      - postgresql_database: postgresql_{{ database }}_db
  {% endfor %}


  {% for host in ['localhost', '%'] %}
postgresql_{{ database }}_{{ host }}_grants:
  postgresql_grants.present:
    - grant: all
    - database: "{{ postgresql['databases'][database]['db_name'] }}.*"
    - user: {{ postgresql['databases'][database]['username'] }}
    - password: {{ postgresql['databases'][database]['password'] }}
    - host: "{{ host }}"
    - connection_user: root
    - connection_pass: {{ postgresql['root_password'] }}
    - connection_charset: utf8
    - require:
      - postgresql_user: postgresql_{{ database }}_{{ host }}_account
  {% endfor %}
{% endfor %}
