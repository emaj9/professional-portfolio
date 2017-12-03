#!/bin/bash

set -e

stack exec professional-portfolio-exe rebuild -- -v
(cd _site ; python -m http.server 8000)
