# coding=utf-8

import os
import sys

load_sh=sys.path[0] +"/load_atlas.sh"
print(load_sh)

os.system(load_sh)
print("load done.")