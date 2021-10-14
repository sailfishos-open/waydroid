Name:           waydroid
Version:        1.1.1
Release:        1
Summary:        Waydroid uses a container-based approach to boot a full Android system on a regular GNU/Linux system like Ubuntu.
License:        GPLv3
URL:            https://github.com/waydroid
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Source1:        anbox.conf
Source2:        waydroid-container.service
Source3:        waydroid-session.service
Source4:        waydroid.conf

Requires:       lxc
Requires:       dnsmasq
Requires:       python-gbinder-python

%description
Waydroid uses Linux namespaces (user, pid, uts, net, mount, ipc) to run a full Android system in a container and provide Android applications on any GNU/Linux-based platform.

The Android system inside the container has direct access to any needed hardware.

The Android runtime environment ships with a minimal customized Android system image based on LineageOS. The image is currently based on Android 10.

%prep
%setup -q

%install
mkdir -p %{buildroot}/opt/waydroid
mkdir -p %{buildroot}/home/waydroid
cp -r upstream/* %{buildroot}/opt/waydroid
mkdir -p %{buildroot}/var/lib/
ln -sf /home/waydroid %{buildroot}/var/lib/waydroid
mkdir -p %{buildroot}/usr/bin
ln -sf /opt/waydroid/waydroid.py %{buildroot}/usr/bin/waydroid

install -D -m644 %{SOURCE1} %{buildroot}/etc/gbinder.d/anbox.conf
install -D -m644 %{SOURCE2} %{buildroot}/%{_unitdir}/waydroid-container.service
install -D -m644 %{SOURCE3} %{buildroot}/%{_userunitdir}/waydroid-session.service
install -D -m644 %{SOURCE4} %{buildroot}/etc/modules-load.d/waydroid.conf

%clean
rm -rf $RPM_BUILD_ROOT

%post
systemctl daemon-reload
systemctl-user daemon-reload

%files
%defattr(-,root,root,-)
/opt/waydroid
%attr(-, defaultuser, users)/home/waydroid
%{_sharedstatedir}/waydroid
%{_sysconfdir}/gbinder.d/anbox.conf
%{_sysconfdir}/modules-load.d/waydroid.conf
%{_bindir}/waydroid
%{_unitdir}/waydroid-container.service
%{_userunitdir}/waydroid-session.service
