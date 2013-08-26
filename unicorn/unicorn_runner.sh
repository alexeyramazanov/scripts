#!/bin/sh

### BEGIN INIT INFO
# Provides:          unicorn
# Required-Start:    $network $remote_fs $local_fs
# Required-Stop:     $network $remote_fs $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Stop/start unicorn
### END INIT INFO

###########################################################
USER=deploy
###########################################################

su - $USER -c "/etc/init.d/unicorn $@"
