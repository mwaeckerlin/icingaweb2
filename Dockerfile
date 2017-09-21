FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

# requires: --link mysql:mysql
ENV WEBPATH /icingaweb2
ENV TIMEZONE "Europe/Zurich"
ENV WEBROOT ""

RUN apt-get update -y && apt-get install -y wget nmap
RUN wget -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/ubuntu icinga-$(lsb_release -sc) main" > /etc/apt/sources.list.d/icinga-main-trusty.list
RUN apt-get update -y && apt-get install -y icingaweb2 libapache2-mod-php php-curl git graphite-carbon
RUN git clone https://github.com/Icinga/icingaweb2-module-director.git /usr/share/icingaweb2/modules/director
RUN git clone https://github.com/findmypast/icingaweb2-module-graphite.git /usr/share/icingaweb2/modules/graphite
RUN echo "" >> /etc/carbon/storage-schemas.conf
RUN echo "[icinga2_internals]" >> /etc/carbon/storage-schemas.conf
RUN echo "pattern = ^icinga2\..*\.(max_check_attempts|reachable|current_attempt|execution_time|latency|state|state_type)" >> /etc/carbon/storage-schemas.conf
RUN echo "retentions = 5m:7d" >> /etc/carbon/storage-schemas.conf
RUN echo "" >> /etc/carbon/storage-schemas.conf
RUN echo "[icinga2_default]" >> /etc/carbon/storage-schemas.conf
RUN echo "pattern = ^icinga2\." >> /etc/carbon/storage-schemas.conf
RUN echo "retentions = 5m:10d,30m:90d,360m:4y" >> /etc/carbon/storage-schemas.conf
RUN touch /firstrun

ADD start.sh /start.sh
CMD /start.sh

EXPOSE 80
VOLUME /etc/icingaweb2
VOLUME /var/log/icingaweb2
