#!/usr/bin/env bash

case $(uname -s) in
    Linux*)
        echo "No time syncing needed"
        ;;
    Darwin*)
        ntpdate pool.ntp.org
        ;;
    CYGWIN_NT*)
        w32tm /resync
        ;;
    *)
        echo Unknown OS \"$(uname_s)\"
        exit 127
        ;;
esac
