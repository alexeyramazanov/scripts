#! /bin/sh
### BEGIN INIT INFO
# Provides:          sidekiq
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

###########################################################
APP_NAME=app
APP_DIR=/var/www/app
CONFIG_FILE=/var/www/app/config/sidekiq.yml
PID_FILE=/var/www/app/tmp/pids/sidekiq.pid
LOG_FILE=/var/www/app/log/sidekiq.log
USER=deploy
ENVIRONMENT=production
TIMEOUT=10
###########################################################
SIDEKIQ_WRAPPER=/usr/local/bin/sidekiq-wrapper
###########################################################

PATH=/usr/local/bin:/usr/local/sbin/:/sbin:/usr/sbin:/bin:/usr/bin

. /lib/init/vars.sh

. /lib/lsb/init-functions

run_simple_cmd() {
  sudo -u $USER $1
}

run_sidekiq_cmd() {
  sudo -u $USER $SIDEKIQ_WRAPPER "$APP_DIR" "$1"
}

do_start() {
  # check if sidekiq is running
  if [ -e $PID_FILE ]; then
    PID=`cat $PID_FILE`
    # If the sidekiq isn't running, run it.
    if [ "`ps -A -o pid= | grep -c $PID`" -eq 0 ]; then
      do_start_do
    else
      log_daemon_msg "---> Sidekiq for $APP_NAME already running."
    fi
  else
    do_start_do
  fi
}

do_start_do() {
  log_daemon_msg "--> Starting sidekiq for $APP_NAME"
  run_sidekiq_cmd "sidekiq --daemon --index 0 --config $CONFIG_FILE --environment $ENVIRONMENT --pidfile $PID_FILE --logfile $LOG_FILE"
}

do_stop() {
  # check if sidekiq is running
  if [ -e $PID_FILE ]; then
    PID=`cat $PID_FILE`
    # If the sidekiq isn't running, remove pidfile.
    if [ "`ps -A -o pid= | grep -c $PID`" -eq 0 ]; then
      log_daemon_msg "---> Sidekiq for $APP_NAME isn't running."
      rm -f $PID_FILE
    else
      do_stop_do
    fi
  else
    log_daemon_msg "---> Sidekiq for $APP_NAME isn't running."
  fi
  return 0
}

do_stop_do() {
  log_daemon_msg "--> Stopping sidekiq for $APP_NAME"
  run_sidekiq_cmd "sidekiqctl stop $PID_FILE $TIMEOUT"
  # Many daemons don't delete their pidfiles when they exit.
  run_simple_cmd "rm -f $PID_FILE"
}

case "$1" in
  start)
    do_start
  ;;
  stop)
    do_stop
  ;;
  restart)
    do_stop
    sleep 2
    do_start
  ;;
  *)
    echo "Usage: sidekiq {start|stop|restart}" >&2
    exit 3
  ;;
esac
