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

### Note about waydroid-gbinder-config packages

A config file is required for libgbinder < 1.1.20.  As of Sailfish 4.4, libgbinder 1.1.18 is shipped.

A config file is provided in packages waydroid-gbinder-config-hybris and waydroid-gbinder-config-mainline, adding a file to
/etc/gbinder.d/
which details the binder nodes and aidl version used for the waydroid release.

A typical file looks like:
```
  [Protocol]
  /dev/puddlejumper = aidl2
  /dev/vndpuddlejumper = aidl2
  /dev/hwpuddlejumper = hidl

  [ServiceManager]
  /dev/puddlejumper = aidl2
  /dev/vndpuddlejumper = aidl2
  /dev/hwpuddlejumper = hidl
```
However, different devices have different binder files, or they may be in another location such as /dev/binderfs/.

Filenames are typically /dev/*puddlejumper and /dev/anbox-*binder and depending on the waydroid version, the aidl version needs to be 2 or 3.

Because of all these combinations, it is easier for a user to provide the config file for their device based on the description above, or the device parter can include the config file with their port.

Once libgbinder 1.1.20 is available in SailfishOS, the config file will no longer be required.

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

## Troubleshooting

### dnsmasq: failed to create listening socket for 192.168.250.1: Address already in use

In case `waydroid-container.service` fails to start with the above error, there are 2 options:

* If the *dnsmasq* service is running, disable it with `devel-su systemctl disable --now dnsmasq`.
* If you would like to keep the *dnsmasq* service alive, edit `/etc/dnsmasq.conf` to uncomment the following line:

    ```
    #bind-interfaces
    ```

  Then restart *dnsmasq* with `devel-su systemctl restart dnsmasq`.

Remember to restart the container service with `devel-su systemctl restart waydroid-container` in either cases.
