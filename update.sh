#!/usr/bin/env bash

tokill=pidof someboringnimbot.noir
kill -p tokill 
git pull origin master
nim c -r bot.nim