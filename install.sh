#!/bin/sh
curl -L -o marquee.tar.gz https://github.com/jamadam/Marquee/tarball/master
curl -L cpanmin.us | perl - -n marquee.tar.gz
rm marquee.tar.gz
