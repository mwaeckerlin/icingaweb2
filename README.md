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
               --link icinga-carbon:carbon \
               --link icinga-graphite:graphite \
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
     - Database Name: `icingaweb`, `WEB_DB` or `Web database` from `docker logs icinga`
     - Username: `icingaweb`, `WEB_USER:` or `Web database user` from `docker logs icinga`
     - Password: …, `WEB_PW` or `Web database password` from `docker logs icinga`
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
     - Database Name: `icinga`, `ICINGA_DB` or `Icinga database` from `docker logs icinga`
     - Username: `icinga`, `ICINGA_USER` or `Icinga database user` from `docker logs icinga`
     - Password: …, `ICINGA_PW` or `Icinga database password` from `docker logs icinga`
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
     - Database Name: `director`, `DIRECTOR_DB` or `Director database` from `docker logs icinga`
     - Username: `director`, `DIRECTOR_USER` or `Director database user` from `docker logs icinga`
     - Password: …, `DIRECTOR_PW` or `Director database password` from `docker logs icinga`
     - Character Set: `utf8`
  - Configuration - Modules - Director:
     - Module: director - State: enable
     - Configuration:
        - DB Resource: `director_db`, as configured above
        - `Create database schema` (wait for a while until background is white)
        - Endpoint Name: … `Director endpoint` from `docker logs icinga`
        - Icinga Host: `icinga`, second part from `--link`
        - Port: `5665`, default is fine
        - API user: `director`, `DIRECTOR_USER` or `Director module user` from `docker logs icinga`
        - Password: …, `DIRECTOR_PW` or `Director module password` from `docker logs icinga`
        - `Run import` (wait for a while until background is white)
        - `Store configuration`
  - Icinga Director: do your configurations


Icinga Director
---------------

Follow some tutorials to use icinga director. When you configured changes, don't forget to go to Deployments - Render config - Deploy to activate your changes.

See, e.g. [Icinga 2 Director – erste Schritte und Nutzung](https://www.unixe.de/icinga2-director-erste-schritte-und-nutzung/) (German).


Execute Over SSH
----------------

To execute check commands over SSH on a remote host, on that remote host create a user `nagios` and allow a password less key based login from the icinga server.

On the target:
```bash
sudo apt install monitoring-plugins bc
cd /usr/lib/nagios/plugins/
sudo wget https://raw.githubusercontent.com/hugme/Nag_checks/master/check_linux_memory
sudo chmod +x check_linux_memory
cd /opt
sudo git clone https://mrw.sh/mwaeckerlin/icinga-checks.git
sudo useradd -m nagios
sudo -Hu nagios mkdir ~nagios/.ssh
sudo -Hu nagios tee -a ~nagios/.ssh/authorized_keys
```

Then paste the ssh public key shown in `docker logs icinga` and terminate with `ctrl+d`.

I (author of this docker image) have my own collection of icinga scripts in [my repository](https://mrw.sh/mwaeckerlin/icinga-check). After the steps above, you have it in `/opt/icinga-scripts`. Run `cd /opt/icinga-scripts; git pull` from time to time to get updates. Feel free to file pull requests if you improve the scripts.

Possible checks are:
 - check disks in linux hosts: I have mountpoints at `/` and `/boot` on all hosts
    - command: `check_by_ssh`
    - arguments:
       - `-H` `$host.name$`
       - `-oStrictHostKeyChecking=no` (empty value)
       - `-C` `/usr/lib/nagios/plugins/check_disk -w 15% -c 10% -p /boot -p /`
 - check memory in linux hosts:
    - command: `check_by_ssh`
    - arguments:
       - `-H` `$host.name$`
       - `-oStrictHostKeyChecking=no` (empty value)
       - `-C` `/usr/lib/nagios/plugins/check_linux_memory`
 - check load per cpu in linux hosts:
    - command: `check_by_ssh`
    - arguments:
       - `-H` `$host.name$`
       - `-oStrictHostKeyChecking=no` (empty value)
       - `-C` `/opt/icinga-scripts/load_per_cpu.sh`


Check Linux Server Using SNMP
-----------------------------

SNMP offer status information about a linux server. You need to run an SNMP daemon on each monitored target install `snmpd` and create a user `nagios` with password `SNMP_PWD` (note that SNMP_PWD should be the same on all hosts, so use `pwgen` only once, this simplifies configuration in icinga):

```bash
SNMP_PWD=$(pwgen 40 1)
echo -e "on other hosts use:\nSNMP_PWD=$SNMP_PWD"
sudo apt install snmpd libsnmp-dev snmp-mibs-downloader
sudo systemctl stop snmpd
sudo net-snmp-config --create-snmpv3-user -ro -X DES -A MD5 -a "$SNMP_PWD" -x "$SNMP_PWD" nagios
sudo sed -i 's,^[^#]*mibs *:,#&,' /etc/snmp/snmp.conf
#sudo sed -i 's,rouser *nagios *,& AuthPriv,' /usr/share/snmp/snmpd.conf
sudo sed -i 's, *AuthPriv,,' /usr/share/snmp/snmpd.conf
sudo systemctl start snmpd
```

In file `/usr/share/snmp/snmpd.conf` append `AuthPriv` to user `nagios` to enforce encryption of connection and password.

Test SNMP configuration:
```bash
/usr/lib/nagios/plugins/check_snmp -H localhost -C public -P 1 -o sysDescr.0
snmpget -v3 -u nagios -l authPriv -a MD5 -x DES -X $SNMP_PWD -A $SNMP_PWD localhost sysDescr.0

```

See:
 - https://wiki.ubuntuusers.de/SNMP/
 - http://mathias-kettner.de/lw_snmp_mibs_fehlen_ubuntu.html