FROM ubuntu
MAINTAINER mwaeckerlin

# requires: --link mysql:mysql
ENV WEBPATH /icingaweb2
ENV TIMEZONE "Europe/Zurich"

RUN apt-get install -y wget nmap
RUN wget -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/ubuntu icinga-$(lsb_release -sc) main" > /etc/apt/sources.list.d/icinga-main-trusty.list
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    icingaweb2 php5-intl php5-gd php5-imagick php5-pgsql php5-mysql
RUN touch /firstrun

CMD if test -z "${MYSQL_ENV_MYSQL_ROOT_PASSWORD}"; then \
      echo "You must link to a MySQL docker container: --link mysql-server:mysql" 1>&2; \
      exit 1; \
    fi; \
    if test -e /firstrun; then \
      echo "Configuration of Icinga Web ..."; \
      head -c 12 /dev/urandom | base64 > /etc/icingaweb2/setup.token; \
      chmod 0660 /etc/icingaweb2/setup.token; \
      chown -R www-data.www-data /etc/icingaweb2; \
      sed -i 's,;\?date.timezone =.*,date.timezone = "'${TIMEZONE}'",g' \
             /etc/php5/apache2/php.ini; \
      mkdir /var/log/icingaweb2; \
      chown www-data.www-data /var/log/icingaweb2; \
      rm  /firstrun; \
      echo "**** Configuration done."; \
      echo "To setup, head your browser to (port can be different):"; \
      echo "  http://localhost:80${WEBPATH}/setup"; \
      echo "and enter the following token:"; \
      echo "  $(cat /etc/icingaweb2/setup.token)"; \
    fi; \
    apache2ctl -DFOREGROUND

EXPOSE 80
VOLUME /etc/icingaweb2
VOLUME /var/log/icingaweb2
