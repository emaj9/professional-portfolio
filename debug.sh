#!/bin/bash

set -e

stack exec professional-portfolio-exe rebuild
(cd _site ; python -m http.server 8000)
