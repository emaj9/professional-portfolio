#!/bin/bash

set -e

rsync _site/ emaj9@emayhew.com:/var/www/html -r
