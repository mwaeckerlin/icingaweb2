#!/bin/bash -e

# template for bash scripts

# internal use only
append_msg() {
    if test $# -ne 0; then
        echo -en ":\e[0m \e[1m$*"
    fi
    echo -e "\e[0m"
}

# write a notice
notice() {
    if test $# -eq 0; then
        return
    fi
    echo -e "\e[1m$*\e[0m" 1>&3
}

# write error message
error() {
    echo -en "\e[1;31merror" 1>&2
    append_msg $* 1>&2
}

# write a warning message
warning() {
    echo -en "\e[1;33mwarning" 1>&2
    append_msg $* 1>&2
}

# write a success message
success() {
    echo -en "\e[1;32msuccess" 1>&2
    append_msg $* 1>&2
}

# commandline parameter evaluation
while test $# -gt 0; do
    case "$1" in
        (--help|-h) less <<EOF
SYNOPSIS

  $0 [OPTIONS]

OPTIONS

  --help, -h                 show this help

DESCRIPTION

  start apache webserver for mwaeckerlin/icingaweb2

EOF
            exit;;
        (*) error "unknow option $1, try $0 --help"; exit 1;;
    esac
    if test $# -eq 0; then
        error "missing parameter, try $0 --help"; exit 1
    fi
    shift;
done

# run a command, print the result and abort in case of error
# option: --no-check: ignore the result, continue in case of error
run() {
    check=1
    while test $# -gt 0; do
        case "$1" in
            (--no-check) check=0;;
            (*) break;;
        esac
        shift;
    done
    echo -en "\e[1m-> running:\e[0m $* ..."
    result=$($* 2>&1)
    res=$?
    if test $res -ne 0; then
        if test $check -eq 1; then
            error "failed with return code: $res"
            if test -n "$result"; then
                echo "$result"
            fi
            exit 1
        else
            warning "ignored return code: $res"
        fi
    else
        success
    fi
}

# error handler
function traperror() {
    set +x
    local err=($1) # error status
    local line="$2" # LINENO
    local linecallfunc="$3"
    local command="$4"
    local funcstack="$5"
    for e in ${err[@]}; do
        if test -n "$e" -a "$e" != "0"; then
            error "line $line - command '$command' exited with status: $e (${err[@]})"
            if [ "${funcstack}" != "main" -o "$linecallfunc" != "0" ]; then
                echo -n "   ... error at ${funcstack} "
                if [ "$linecallfunc" != "" ]; then
                    echo -n "called at line $linecallfunc"
                fi
                echo
            fi
            exit $e
        fi
    done
    success
    exit 0
}

# catch errors
trap 'traperror "$? ${PIPESTATUS[@]}" $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[@]}" "${FUNCTION}"' ERR SIGINT INT TERM EXIT

###########################################################################################

echo "Configuration of Icinga Web ..."
if ! test -e /etc/icingaweb2/setup.token; then
    head -c 12 /dev/urandom | base64 > /etc/icingaweb2/setup.token
    chmod 0660 /etc/icingaweb2/setup.token
fi
chown -R www-data.www-data /etc/icingaweb2
sed -i 's,;*date.timezone =.*,date.timezone = "'${TIMEZONE}'",g' \
    /etc/php/7.0/apache2/php.ini
test -d /var/log/icingaweb2 || mkdir -p /var/log/icingaweb2
chown www-data.www-data /var/log/icingaweb2
sed -i "s,web_url = .*,web_url = ${GRAPHITE_WEB}," /etc/icingaweb2/modules/graphite/config.ini
sed -i "s,Alias.*,Alias ${WEBROOT%/}/ /usr/share/icingaweb2/public/,;s,RewriteBase.*,RewriteBase ${WEBROOT%/}/," /etc/apache2/conf-available/icingaweb2.conf
echo "**** Configuration done."
echo "To setup, head your browser to (port can be different):"
echo "  http://localhost:80${WEBROOT%/}/setup"
echo "and enter the following token:"
echo "  $(cat /etc/icingaweb2/setup.token)"

if test -f /run/apache2/apache2.pid; then
    rm /run/apache2/apache2.pid;
fi
! test -f /var/run/icinga2/cmd/icinga2.cmd || chmod o+rw /var/run/icinga2/cmd/icinga2.cmd
apache2ctl -DFOREGROUND
