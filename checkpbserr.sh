#!/bin/bash
if ls *.err*; then
  tput setaf 1
  more *.err* | grep -i -e error -e PBS -e make
  tput setaf 3
  more *.err* | fgrep -i warning
  tput sgr0
fi