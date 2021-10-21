# Waydroid sailfish packaging

## User Usage

* Install this package
* As root (devel-su) run the command 'waydroid init' which will download the required root filesytems
* Reboot (container service will start next boot)
* Goto jolla settings > waydroid and start the "Session" service (you can choose to start it automatically)
* Click on the Waydroid icon launcher, this will start the fullscreen waydroid UI

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
* Android vibration service is disabled in Sailfish and needs to be enabled for waydroid
