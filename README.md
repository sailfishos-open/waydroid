# Waydroid sailfish packaging

## User Usage

* Install this package
* As defaultuser run the command 'waydroid init' which will download the required root filesytems
* As root, run the command 'systemctl start waydroid-container'
* As defaultuser, run the command 'systemctl start waydroid-session'
* As defaultuser, run the command 'waydroid show-full-ui'

And hopefully you will be presented with an android window

## Porter tasks

* Ensure the kernel is built with puddlejumper,hwpuddlejumper and vndpuddlejumper binder nodes
* Ensure the kernel is build with CONFIG_VETH and CONFIG_NETFILTER_XT_TARGET_CHECKSUM.  Other configs may also be requried, see https://github.com/waydroid/waydroid/blob/lineage-17.1/scripts/check-kernel-config.sh
* If some options are built as modules, add them to /etc/modules-load.d, eg
  
```
cat /etc/modules-load.d/waydroid.conf 
veth
xt_CHECKSUM
```
