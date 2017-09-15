Docker Image for Icinga2 with Web-Management
============================================

Use [mwaeckerlin/icinga2ido](https://github.com/mwaeckerlin/icinga2ido) and [mwaeckerlin/icingaweb2](https://github.com/mwaeckerlin/icingaweb2) together with [mysql](https://hub.docker.com/r/_/mysql/) to get a complete icinga system monitoring with web gui and icinga director for configuration management.

Usage
-----

First follow the steps in the [README.md in mwaeckerlin/icinga2ido](https://github.com/mwaeckerlin/icinga2ido/blob/master/README.md), then you have a running icinga server with a database that is prepared for the web frontend. So continue with this:

        docker run -d --restart unless-stopped --name icingaweb-volumes \
               mwaeckerlin/icingaweb2 sleep infinity
        docker run -d --restart unless-stopped --name icingaweb \
               -p 8080:80 \
               --link icinga-mysql:mysql \
               --link icinga:icinga \
               --volumes-from icinga \
               --volumes-from icingaweb-volumes \
               mwaeckerlin/icingaweb2

See the log to get the next step, the passwords and the installatin token:

        docker logs icinga
        docker logs icingaweb

As instructed in the logs, head to http://localhost:8080/icinga2/setup to interactively configure the web interface.

With the above container configuration, you need to know the following parameter:
  - Setup Token: See logs of mwaeckerlin/icingaweb2, e.g. `docker logs icingaweb`
  - Authentication Type: Database (you could also use an LDAP server if you want)
     - Resource Name: `icingaweb_db`, or whatever you want
     - Database Type: `MySQL`
     - Host: `mysql`, second part from `--link`
     - Port: empty is fine
     - Database Name: `icingaweb`, `Web database` from `docker logs icinga`
     - Username: `icingaweb`, `Web database user` from `docker logs icinga`
     - Password: …, `Web database password` from `docker logs icinga`
     - Character Set: `utf8`
  - Backend Name: `icingaweb2`, or whatever you want
  - Administration:
     - Username: your username to login to the web ui, whatever you want
     - Password: your password to login to the web ui, whatever you want
  - Application Configuration
     - Show Stacktraces: checked, or whatever you want
     - User Preference Storage Type: `Database`
     - Logging Type: `File` (or `None`, but there's no `Syslog` daemon in docker)
     - Logging Level: `Error` or whatever you want
     - File path: `/var/log/icingaweb2/icingaweb2.log`, the default is fine
  - Monitoring Backend:
     - Backend Name: `icinga`, or whatever you want
     - Backend Type: `IDO`
  - Monitoring IDO Resource:
     - Resource Name: `icinga_ido`, or whatever you want
     - Database Type: `MySQL`
     - Host: `mysql`, second part from `--link`
     - Port: empty is fine
     - Database Name: `icinga`, `MYSQL_ENV_MYSQL_DATABASE` from `docker logs icingaweb`
     - Username: `icinga`, `MYSQL_ENV_MYSQL_USER` from `docker logs icingaweb`
     - Password: …, `MYSQL_ENV_MYSQL_PASSWORD` from `docker logs icingaweb`
     - Character Set: `utf8`
  - Command Transport:
     - Transport Name: `icinga2`, or whatever you want
     - Command File: `/var/run/icinga2/cmd/icinga2.cmd` (this path is mandatory)
  - Monitoring Security:
     - Protected Custom Variables: `*pw*,*pass*,community` (default is fine)

After login to icinga web, you must setup the director plugin:

  - Configuration - Resources - Create a New Resource
     - Resource Type: SQL Database
     - Resource Name: `director_db`, or whatever you want
     - Database Type: `MySQL`
     - Host: `mysql`, second part from `--link`
     - Port: empty is fine
     - Database Name: `director`, `Director database` from `docker logs icinga`
     - Username: `director`, `Director database user` from `docker logs icinga`
     - Password: …, `Director database password` from `docker logs icinga`
     - Character Set: `utf8`
  - Configuration - Modules - Director:
     - Module: director - State: enable
     - Configuration:
        - DB Resource: `director_db`, as configured above
        - `Create database schema` (wait for a while until background is white)
        - Endpoint Name: … `Director endpoint` from `docker logs icinga`
        - Icinga Host: `icinga`, second part from `--link`
        - Port: `5665`, default is fine
        - API user: `director`, `Director module user` from `docker logs icinga`
        - Password: …, `Director module password` from `docker logs icinga`
        - `Run import` (wait for a while until background is white)
        - `Store configuration`
  - Icinga Director: do your configurations
