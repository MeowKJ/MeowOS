# SD card offline diagnostics

Meow OS keeps persistent systemd journal data in `/var/log/journal` and compact
boot/failure snapshots in `/var/log/meow-os`. The latter includes kernel logs,
failed units, display/input/storage discovery, source fingerprint and Meow OS
service output. If the kernel exposes pstore/ramoops records, they are copied to
`/var/log/meow-os/pstore` on the next boot.

On macOS, insert the SD card, identify its ext4 root partition with
`diskutil list external physical`, then run:

```sh
sudo tools/extract-sd-diagnostics.sh /dev/rdisk6s3
```

The extractor uses `e2fsck -fn` and `debugfs`; it does not mount, repair or
write the SD card. The device name may differ after reinsertion.

