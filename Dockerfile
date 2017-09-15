FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

# requires: --link mysql:mysql
ENV WEBPATH /icingaweb2
ENV TIMEZONE "Europe/Zurich"

RUN apt-get update -y && apt-get install -y wget nmap
RUN wget -O - http://packages.icinga.org/icinga.key | apt-key add -
RUN echo "deb http://packages.icinga.org/ubuntu icinga-$(lsb_release -sc) main" > /etc/apt/sources.list.d/icinga-main-trusty.list
RUN apt-get update -y && apt-get install -y icingaweb2 libapache2-mod-php php-curl git
RUN git clone https://github.com/Icinga/icingaweb2-module-director.git /usr/share/icingaweb2/modules/director
RUN touch /firstrun

ADD start.sh /start.sh
CMD /start.sh

EXPOSE 80
VOLUME /etc/icingaweb2
VOLUME /var/log/icingaweb2
