#!/bin/bash
#
## Alsaequal setup script
## This is the full installation script including compilation
#

pkgname=alsaequal
pkgver=0.6
pkgrel=2
declare -a depends=('caps' 'libasound2-dev')

echo "Installing $pkgname"

#Dependencies
for deppkg in "${depends[@]}"
do
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $deppkg|grep "install ok installed")
    echo Checking for package: $deppkg
    if [ "" == "$PKG_OK" ]; then
        echo Installing package: $deppkg
        aptitude install $deppkg
    else
        echo Package already installed: $deppkg
    fi
done

cd /tmp

#Get the main install base and compile
wget http://www.thedigitalmachine.net/tools/$pkgname-$pkgver.tar.bz2
tar -xvf $pkgname-$pkgver.tar.bz2

cd $pkgname

# Patch some files (per ArchPhil playground install
# Makefile
sed 's/-m 644 $(SND/-m 755 $(SND/' -i Makefile

#ctl_equal.c
sed 's/module = "Eq"/module = "Eq10"/' -i ctl_equal.c
sed 's/if(equal->klass->PortDescriptors\[index\] !=/if(equal->klass->PortDescriptors\[index\] \&/' -i ctl_equal.c
sed 's/(LADSPA_PORT_INPUT | LADSPA_PORT_CONTROL)) {/(LADSPA_PORT_INPUT | LADSPA_PORT_CONTROL) == 0) {/' -i ctl_equal.c

#pcm_equal.c
sed 's/module = "Eq"/module = "Eq10"/' -i pcm_equal.c

#Compile
make
install -dm755 "/usr/lib/alsa-lib"
make install
install -m 755 libasound_module_pcm_equal.so /usr/lib/arm-linux-gnueabihf/alsa-lib/libasound_module_pcm_equal.so
install -m 755 libasound_module_ctl_equal.so /usr/lib/arm-linux-gnueabihf/alsa-lib/libasound_module_ctl_equal.so

#Cleanup
cd /tmp
rm $pkgname-$pkgver.tar.bz2
rm -r $pkgname

#Get the config file and service file
wget https://raw.githubusercontent.com/Yarny998/MPD-Jesse-Lite/master/Packages/AlsaEqual/asound.conf

# Install files
install -D -m644 asound.conf "/etc/asound.conf"

#make a copy of the standard settings
cp /var/lib/mpd/.alsaequal.bin /var/lib/mpd/.alsaequal.bin.std

#Cleanup
rm asound.conf
