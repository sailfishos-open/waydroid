Name:           waydroid
Version:        1.1.1
Release:        1
Summary:        Waydroid uses a container-based approach to boot a full Android system on a regular GNU/Linux system like Ubuntu.
License:        GPLv3
URL:            https://github.com/waydroid
Source0:        %{name}-%{version}.tar.gz
Source1:        anbox.conf

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
mkdir -p %{buildroot}/etc/gbinder.d
chown 10000:10000 %{buildroot}/home/waydroid
cp -r upstream/* %{buildroot}/opt/waydroid
mkdir -p %{buildroot}/var/lib/
ln -sf /home/waydroid %{buildroot}/var/lib/waydroid
mkdir -p %{buildroot}/usr/bin
ln -sf /opt/waydroid/waydroid.py %{buildroot}/usr/bin/waydroid

install -m644 %{SOURCE1} %{buildroot}/etc/gbinder.d/

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
/opt/waydroid
/home/waydroid
%{_sharedstatedir}/waydroid
%{_sysconfdir}/gbinder.d/anbox.conf
%{_bindir}/waydroid
