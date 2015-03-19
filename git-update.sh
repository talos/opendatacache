#!/bin/bash -e

# Automatic update from origin/master
git fetch origin
git stash
git clean -f
git checkout origin/master
git checkout -B master
