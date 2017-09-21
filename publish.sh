#!/bin/bash
# wangsuwen
# 2017/9/22 01:36:31

set -ev

git clone https://${GH_REF} .old
cd .old
git checkout master
cd ..
mv .old/.git .public/

cd ./public
git config user.name "roccowang"
git config user.email "roccowang95@outlook.com"

git add .
git commit -m "Travis CI built at $(date +"%Y-%m-%d %H:%M")"
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:master
