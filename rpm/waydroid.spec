Name:           waydroid
Version:        1.4.3
Release:        1
Summary:        Container-based approach to boot a full Android system
License:        GPLv3
URL:            https://waydro.id/
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Patch0:         0001-disable-user-manager.patch
Patch1:         0002-Remove-apparmor-reference-in-config_3.patch

BuildRequires:  systemd
BuildRequires:  desktop-file-utils
Requires:       lxc
Requires:       dnsmasq
Requires:       python3-gbinder
Requires:       python3-gobject
Requires:       python3-dbus
Requires:       waydroid-sensors

%description
Waydroid uses Linux namespaces (user, pid, uts, net, mount, ipc) to run a full Android system in a container and provide Android applications on any GNU/Linux-based platform.

The Android system inside the container has direct access to any needed hardware.

The Android runtime environment ships with a minimal customized Android system image based on LineageOS. The image is currently based on Android 10.

Custom:
  Repo: https://github.com/waydroid/waydroid
Type: console-application
Icon: https://raw.githubusercontent.com/waydroid/waydroid/bullseye/data/AppIcon.png
Categories:
  - System

%package settings
Summary: System Settings module for Waydroid
Requires: %{name} = %{version}

%description settings
Support for enabling Waydroid session as a systemd service and use of Waydroid through direct rendering on Sailfish composer.

Custom:
  Repo: https://github.com/sailfishos-open/waydroid
Icon: https://raw.githubusercontent.com/waydroid/waydroid/bullseye/data/AppIcon.png
Categories:
  - System

%package gbinder-config-hybris
Summary: gbinder config for hybris ports
Requires: %{name} = %{version}
Provides: waydroid-gbinder-config
Conflicts: waydroid-gbinder-config-mainline

%description gbinder-config-hybris
Provides the gbinder config required for waydroid based on typical hybris based ports

%package gbinder-config-mainline
Summary: gbinder config for mainline ports
Requires: %{name} = %{version}
Provides: waydroid-gbinder-config
Conflicts: waydroid-gbinder-config-hybirs

%description gbinder-config-mainline
Provides the gbinder config required for waydroid based on mainline (native) kernel

%prep
%autosetup -p1 -n %{name}-%{version}/upstream

%install

make install DESTDIR=%{buildroot} USE_SYSTEMD=0

install -D -m644 ../config/waydroid-container.service %{buildroot}/%{_unitdir}/waydroid-container.service
install -D -m644 ../config/waydroid-session.service %{buildroot}/%{_userunitdir}/waydroid-session.service
install -D -m644 ../config/waydroid.conf %{buildroot}/etc/modules-load.d/waydroid.conf

# Settings files
install -D -m644 ../settings/waydroid.json %{buildroot}/usr/share/jolla-settings/entries/waydroid.json
install -D -m644 ../settings/Waydroid.qml %{buildroot}/usr/share/waydroid/settings/Waydroid.qml

desktop-file-install ../config/waydroid.desktop

#Place waydroid images in /home for space
mkdir -p %{buildroot}/var/lib/
mkdir -p %{buildroot}/home/waydroid
ln -sf /home/waydroid %{buildroot}/var/lib/waydroid

#Sample gbinder config
install -D -m644 ../config/anbox-hybris.conf %{buildroot}/etc/gbinder.d/anbox-hybris.conf
install -D -m644 ../config/anbox-mainline.conf %{buildroot}/etc/gbinder.d/anbox-mainline.conf

#Remove less useful file
rm -f %{buildroot}/usr/share/applications/Waydroid.desktop
rm -f %{buildroot}/usr/share/applications/waydroid.market.desktop
rm -f %{buildroot}/etc/xdg/menus/applications-merged/waydroid.menu

%clean
rm -rf $RPM_BUILD_ROOT

%pre
if [ $1 == 2 ]; then
# Existing config might have apparmor reference, remove it on upgrade since SailfishOS doesn't use apparmor
  sed -i '/apparmor/d' %{_sharedstatedir}/waydroid/lxc/waydroid/config || :
# Existing config pre 1.4 might not have config_session included. Append it if not, after config_nodes.
  grep config_session %{_sharedstatedir}/waydroid/lxc/waydroid/config || sed -e '/config_nodes/a\' -e 'lxc.include = %{_sharedstatedir}/waydroid/lxc/waydroid/config_session' -i %{_sharedstatedir}/waydroid/lxc/waydroid/config
fi

%post
systemctl daemon-reload
systemctl-user daemon-reload
systemctl enable waydroid-container

%files
%defattr(-,root,root,-)
%attr(-, defaultuser, users)/home/waydroid
%{_sharedstatedir}/waydroid
%{_sysconfdir}/modules-load.d/waydroid.conf
%{_bindir}/waydroid
%{_prefix}/lib/waydroid
%{_unitdir}/waydroid-container.service
%{_datadir}/dbus-1/
%{_datadir}/applications/
%{_datadir}/desktop-directories/
%{_datadir}/icons/
%{_datadir}/metainfo/
%{_datadir}/polkit-1/

%files settings
%defattr(-,root,root,-)
%{_userunitdir}/waydroid-session.service
%{_datadir}/jolla-settings/entries/waydroid.json
%{_datadir}/waydroid/settings/Waydroid.qml
%{_datadir}/applications/waydroid.desktop

%files gbinder-config-hybris
%defattr(-,root,root,-)
%{_sysconfdir}/gbinder.d/anbox-hybris.conf

%files gbinder-config-mainline
%defattr(-,root,root,-)
%{_sysconfdir}/gbinder.d/anbox-mainline.conf
