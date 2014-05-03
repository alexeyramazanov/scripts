#! /bin/sh
### BEGIN INIT INFO
# Provides:          puma
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

# Based on original puma init script by Darío Javier Cravero <dario@exordo.com>
# https://github.com/puma/puma/tree/master/tools/jungle/init.d

###########################################################
APP_NAME=app
APP_DIR=/var/www/app
CONFIG_FILE=/var/www/app/config/puma.rb
PID_FILE=/var/www/app/tmp/pids/puma.pid
STATE_FILE=/var/www/app/tmp/pids/puma.state
USER=deploy
ENVIRONMENT=production
###########################################################
PUMA_WRAPPER=/usr/local/bin/puma-wrapper
###########################################################

PATH=/usr/local/bin:/usr/local/sbin/:/sbin:/usr/sbin:/bin:/usr/bin

. /lib/init/vars.sh

. /lib/lsb/init-functions

run_simple_cmd() {
  sudo -u $USER $1
}

run_puma_cmd() {
  sudo -u $USER $PUMA_WRAPPER "$APP_DIR" "$1"
}

do_start() {
  # check if puma is running
  if [ -e $PID_FILE ]; then
    PID=`cat $PID_FILE`
    # If the puma isn't running, run it.
    if [ "`ps -A -o pid= | grep -c $PID`" -eq 0 ]; then
      do_start_do
    else
      log_daemon_msg "---> $APP_NAME already running."
    fi
  else
    do_start_do
  fi
}

do_start_do() {
  log_daemon_msg "--> Starting $APP_NAME"
  run_puma_cmd "puma -C $CONFIG_FILE"
}

do_stop() {
  # check if puma is running
  if [ -e $PID_FILE ]; then
    PID=`cat $PID_FILE`
    # If the puma isn't running, remove pidfile.
    if [ "`ps -A -o pid= | grep -c $PID`" -eq 0 ]; then
      log_daemon_msg "---> $APP_NAME isn't running."
      rm -f $PID_FILE
    else
      do_stop_do
    fi
  else
    log_daemon_msg "---> $APP_NAME isn't running."
  fi
  return 0
}

do_stop_do() {
  log_daemon_msg "--> Stopping $APP_NAME"
  run_puma_cmd "pumactl --state $STATE_FILE stop"
  # Many daemons don't delete their pidfiles when they exit.
  run_simple_cmd "rm -f $PID_FILE $STATE_FILE"
}

do_restart() {
  # check if puma is running
  if [ -e $PID_FILE ]; then
    PID=`cat $PID_FILE`
    # If the puma isn't running, start it.
    if [ "`ps -A -o pid= | grep -c $PID`" -eq 0 ]; then
      log_daemon_msg "---> $APP_NAME isn't running."
      do_start
    else
      log_daemon_msg "--> Restarting $APP_NAME"
      run_puma_cmd "pumactl --state $STATE_FILE restart"
    fi
  else
    log_daemon_msg "---> $APP_NAME isn't running."
    do_start
  fi
	return 0
}

case "$1" in
  start)
    do_start
  ;;
  stop)
    do_stop
  ;;
  restart)
    do_restart
  ;;
  *)
    echo "Usage: puma {start|stop|restart}" >&2
    exit 3
  ;;
esac
