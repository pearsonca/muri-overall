#!/bin/bash
if [ls *err*]; then
  tput setaf 1
  more *err* | grep -i -e (error|PBS|make)
  tput setaf 3
  more *err* | grep -i warning
  tput sgr0
fi