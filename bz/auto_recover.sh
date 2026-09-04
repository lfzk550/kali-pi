#!/bin/bash

/bz/sync_init.sh

/root/bz-startup/main.sh

nohup /bz/sync_daemon.sh >/dev/null 2>&1 &
