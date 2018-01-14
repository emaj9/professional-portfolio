#!/bin/bash

set -e

stack exec professional-portfolio-exe rebuild -- -v
rsync _site/ /var/www/html -r

