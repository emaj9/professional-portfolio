#!/bin/bash

set -e

stack exec 1st-try-git-exe rebuild
(cd _site ; python -m http.server 8000)
