# Docker Image to run Icinga2 Webinterface - attach to Icinga2 IDO Docker Container

This is the web user interface only to icinga2. First of all, you need a mwaeckerlin/icinga2ido docker container instance. See there for basic configuration.

You must at least link your container to the icinga2 ido mysql database and to get the volumes from the icimga2 ido container to be able to connect the web user interface to the icinga2 ido instance. 

If you want, you can link to a second mysql database to store your web interface configuration in a different database.

This is an example setup with two databases:
        docker run -d --name icinga-mysql -e MYSQL_ROOT_PASSWORD=1234 mysql
        docker run -d --name icinga --link icinga-mysql:mysql mwaeckerlin/icinga2ido
        docker run -d --name icingaweb-mysql -e MYSQL_ROOT_PASSWORD=1234 mysql
        docker run -d --name icingaweb-volume mwaeckerlin/icingaweb2 sleep infinity
        docker run -d --name icingaweb --link icinga-mysql:icingadb --link icingaweb-mysql:webdb --volumes-from icingaweb-volume -p 80:80 mwaeckerlin/icingaweb2

After you started the containers, head to http://localhost/icinga2/setup to interactively configure the web interface.

With the above container configuration, you need to know the following parameter:
  - Setup Token: See logs of mwaeckerlin/icingaweb2, e.g. `docker logs icinga-web`
  - Authentication Typ: Database - here let's use container `web-mysql` (see above)
  - Database Resource: (database is from container `web-mysql`, aliased to `webdb`)
     - Database Type: MySQL
     - Host: webdb (see above)
     - Database Name: icingaweb (can be anything you want)
     - Username: icingaweb (can be anything you want)
     - Password: AnyThingYouWant (can be anything you want)
  - Database Setup: (database is from container `web-mysql`, aliased to `webdb`)
     - Username: root
     - Password: 1234 (see `MYSQL_ROOT_PASSWORD` above)
  - Administration: choose any username / password to login as administrator to the web interface
  - Application Configuration:
     - User Preference Storage Type: Database (recommended - goes to `web-mysql`)
     - Logging Type: File (Syslog is not installed)
     - File path: /var/log/icingaweb2/icingaweb2.log (this path is writable to apache)
  - Monitoring IDO Resource: (database is from container `icinga-mysql`, aliased to `icingadb`)
     - Database Type: MySQL
     - Host: icingadb (see above)
     - Database Name: icinga2 (see mwaeckerlin/icinga2ido, here see `database` in `docker log icinga`)
     - Username: icinga2 (see mwaeckerlin/icinga2ido, here see `user` in `docker log icinga`)
     - Password: (see mwaeckerlin/icinga2ido, here see `password` in `docker log icinga`)
  - Command Transport: defaults are fine, thanks to `--volumes-from icinga`
     - Transport Type: Local Command File
     - Command File: /var/run/icinga2/cmd/icinga2.cmd

For everything else, the defaults are fine, or choose anything you want.
