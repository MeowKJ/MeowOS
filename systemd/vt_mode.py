#!/usr/bin/python3
import fcntl
import os
import sys

if len(sys.argv) != 2 or sys.argv[1] not in ("text", "graphics"):
    raise SystemExit("usage: vt_mode.py text|graphics")
fd = os.open("/dev/tty1", os.O_RDWR | os.O_CLOEXEC)
try:
    fcntl.ioctl(fd, 0x4B3A, 1 if sys.argv[1] == "graphics" else 0)
finally:
    os.close(fd)
