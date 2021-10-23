Name:           waydroid
Version:        1.2.0
Release:        3
Summary:        Waydroid uses a container-based approach to boot a full Android system on a regular GNU/Linux system like Ubuntu.
License:        GPLv3
URL:            https://github.com/waydroid
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Patch0:         0001-disable-user-manager.patch

BuildRequires:  systemd
BuildRequires:  desktop-file-utils
Requires:       lxc
Requires:       dnsmasq
Requires:       python3-gbinder
Requires:       python3-gobject
Requires:       waydroid-sensors

%description
Waydroid uses Linux namespaces (user, pid, uts, net, mount, ipc) to run a full Android system in a container and provide Android applications on any GNU/Linux-based platform.

The Android system inside the container has direct access to any needed hardware.

The Android runtime environment ships with a minimal customized Android system image based on LineageOS. The image is currently based on Android 10.

%package settings
Summary: System Settings module for Waydroid
Requires: %{name} = %{version}

%description settings
Support for enabling Waydroid session as a systemd service and use of Waydroid through direct rendering on Sailfish composer.

%prep
%setup
%patch0 -p1

%install
mkdir -p %{buildroot}/opt/waydroid
mkdir -p %{buildroot}/home/waydroid
cp -r upstream/* %{buildroot}/opt/waydroid
mkdir -p %{buildroot}/var/lib/
ln -sf /home/waydroid %{buildroot}/var/lib/waydroid
mkdir -p %{buildroot}/usr/bin
ln -sf /opt/waydroid/waydroid.py %{buildroot}/usr/bin/waydroid

install -D -m644 config/anbox.conf %{buildroot}/etc/gbinder.d/anbox.conf
install -D -m644 config/waydroid-container.service %{buildroot}/%{_unitdir}/waydroid-container.service
install -D -m644 config/waydroid-session.service %{buildroot}/%{_userunitdir}/waydroid-session.service
install -D -m644 config/waydroid.conf %{buildroot}/etc/modules-load.d/waydroid.conf

# Settings files
install -D -m644 settings/waydroid.json %{buildroot}/usr/share/jolla-settings/entries/waydroid.json
install -D -m644 settings/Waydroid.qml %{buildroot}/usr/share/waydroid/settings/Waydroid.qml

desktop-file-install config/waydroid.desktop

%clean
rm -rf $RPM_BUILD_ROOT

%post
systemctl daemon-reload
systemctl-user daemon-reload
systemctl enable waydroid-container

%files
%defattr(-,root,root,-)
/opt/waydroid
%attr(-, defaultuser, users)/home/waydroid
%{_sharedstatedir}/waydroid
%{_sysconfdir}/gbinder.d/anbox.conf
%{_sysconfdir}/modules-load.d/waydroid.conf
%{_bindir}/waydroid
%{_unitdir}/waydroid-container.service

%files settings
%defattr(-,root,root,-)
%{_userunitdir}/waydroid-session.service
%{_datadir}/jolla-settings/entries/waydroid.json
%{_datadir}/waydroid/settings/Waydroid.qml
%{_datadir}/applications/waydroid.desktop
