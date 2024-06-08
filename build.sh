#!/bin/sh
set -e
cd /archiso
mkarchiso -v .
mv out/*.iso /archiso-out/