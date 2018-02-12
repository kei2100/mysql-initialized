#!/bin/bash

#
# Script for initialize database.
# This file based on mysql:5.7 docker-entrypoint.sh .
#

#HOST_ADDR=$(ip route | awk 'NR==1 {print $3}')
HOST_ADDR='%'
MYSQL="mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock"

mysqld --skip-networking --socket=/var/run/mysqld/mysqld.sock &
PID="$!"

for i in {30..0}; do
	if mysqladmin ping --silent; then
		break
	fi
	echo 'MySQL init process in progress...'
	sleep 1
done
if [ "$i" = 0 ]; then
  echo >&2 'MySQL init process failed.'
  exit 1
fi

# sed is for https://bugs.mysql.com/bug.php?id=20545
mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | ${MYSQL} mysql

echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'${HOST_ADDR}' IDENTIFIED BY 'root' WITH GRANT OPTION;" | ${MYSQL}

for f in /init_db.d/*; do
	case "$f" in
		*.sh)     echo "$0: running $f"; . "$f" ;;
		*.sql)    echo "$0: running $f"; ${MYSQL} < "$f"; echo ;;
		*.sql.gz) echo "$0: running $f"; gunzip -c "$f" | ${MYSQL}; echo ;;
		*)        echo "$0: ignoring $f" ;;
	esac
	echo
done

if ! kill -s TERM "${PID}" || ! wait "${PID}"; then
	echo >&2 'MySQL init process failed.'
	exit 1
fi

echo
echo 'MySQL init process done. Ready for start up.'
echo

