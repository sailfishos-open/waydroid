# Waydroid Sailfish OS packaging

## User Usage

You can run Waydroid session either by starting it as a systemd
service (on boot or on request) or through dedicated app. As it is
recommended to run Waydroid using its full UI mode, UI is similar in
the both approaches.

When using Waydroid through systemd services, Waydroid settings are
available as a module of Sailfish Settings. These allow you to request
starting the session on boot and start/stop session. UI of the session
will be opened with the launcher on applications grid. Main drawback
of using UI via this approach is that if you close the UI in Lipstick,
it will not open again due to some issue in interaction between
Lipstick and Waydroid. To use this approach, install package
*waydroid-settings*.

In the case of the dedicated app, Waydroid session will be started
with start of the app and closed with the app. As a result, it is
slower to start than using pre-started Waydroid session via
systemd. In addition, as it is using nested Wayland composer, it is
expected to be slower than running directly on Lipstick. The dedicated
app can be installed via *waydroid-runner* package.

* Install `waydroid-settings` or `waydroid-runner` package.
* Install `waydroid-gbinder-config-hybris` or `waydroid-gbinder-config-mainline` depending on the type of device you have
* As root (devel-su) run the command `waydroid init` which will download the required root filesystems. See `waydroid init -h` for the list of available images.
* Reboot (container service will start next boot).

If using *waydroid-settings*:
* Goto Jolla Settings > Waydroid and start the "Session" service (you can choose to start it automatically)
* Click on the Waydroid icon launcher, this will start the fullscreen waydroid UI

If using *waydroid-runner*, start it from the launcher.

It is expected that you will be presented with an Android window.

## Porter tasks

* Ensure the kernel is built with puddlejumper,hwpuddlejumper and vndpuddlejumper binder nodes
* Ensure the kernel is build with CONFIG_VETH and CONFIG_NETFILTER_XT_TARGET_CHECKSUM.  Other configs may also be requried, see https://github.com/waydroid/waydroid/blob/lineage-17.1/scripts/check-kernel-config.sh
* If some options are built as modules, add them to /etc/modules-load.d, eg
  
```
cat /etc/modules-load.d/waydroid.conf 
veth
xt_CHECKSUM
```
* Android vibration service is disabled in Sailfish and needs to be enabled for Waydroid
