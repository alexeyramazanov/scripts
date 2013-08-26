#!/usr/bin/env bash

###########################################################
RVM=true
RVM_RUBY_VER=2.0.0-p247
RVM_GEMSET=rails32
###########################################################
APP_DIR=/var/www/app
SHARED_DIR=/var/www/app
ENVIRONMENT=production
###########################################################

TIMEOUT=${TIMEOUT-60}
PID="$SHARED_DIR/tmp/pids/unicorn.pid"
CMD="unicorn -D -c $APP_DIR/config/unicorn.conf.rb -E $ENVIRONMENT"
old_pid="$PID.oldbin"
action="$1"

set -e

if $RVM; then
	if [ -z "$RVM_GEMSET" ]; then
		RVM_STRING="$RVM_RUBY_VER"
	else
		RVM_STRING="$RVM_RUBY_VER@$RVM_GEMSET"
	fi

	# Load RVM into a shell session *as a function*
	if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
		source "$HOME/.rvm/scripts/rvm"
	elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
		source "/usr/local/rvm/scripts/rvm"
	else
		printf "ERROR: An RVM installation was not found.\n"
	fi

	rvm use $RVM_STRING
fi

sig () {
	test -s "$PID" && kill -$1 `cat $PID`
}

oldsig () {
	test -s $old_pid && kill -$1 `cat $old_pid`
}

case $action in
start)
	sig 0 && echo >&2 "Already running" && exit 0
	$CMD
	;;
stop)
	sig QUIT && exit 0
	echo >&2 "Not running"
	;;
force-stop)
	sig TERM && exit 0
	echo >&2 "Not running"
	;;
restart|reload)
	echo >&2 "NOTE: this will not reload your app code if you have 'preload_app true' in unicorn config"
	echo >&2 "NOTE: use upgrade instead of restart/reload"
	sig HUP && echo "reloaded OK" && exit 0
	echo >&2 "Couldn't reload, starting '$CMD' instead"
	$CMD
	;;
upgrade)
	if sig USR2 && sleep 2 && sig 0 && oldsig QUIT
	then
		n=$TIMEOUT
		while test -s $old_pid && test $n -ge 0
		do
			printf '.' && sleep 1 && n=$(( $n - 1 ))
		done
		echo

		if test $n -lt 0 && test -s $old_pid
		then
			echo >&2 "$old_pid still exists after $TIMEOUT seconds"
			exit 1
		fi
		exit 0
	fi
	echo >&2 "Couldn't upgrade, starting '$CMD' instead"
	$CMD
	;;
reopen-logs)
	sig USR1
	;;
*)
	echo >&2 "Usage: $0 <start|stop|restart|upgrade|force-stop|reopen-logs>"
	exit 1
	;;
esac
