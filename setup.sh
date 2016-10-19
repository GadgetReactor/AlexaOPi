#! /bin/bash
cwd=`pwd`
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

chmod +x *.sh

read -p "Would you like to also install Airplay support (Y/n)? " shairport

case $shairport in
        [nN] ) 
        	echo "shairport-sync (Airplay) will NOT be installed."
        ;;
        * )
        	echo "shairport-sync (Airplay) WILL be installed."
        ;;
esac

read -p "Would you like to add always-on monitoring (Y/n)? " monitorAlexa

case $monitorAlexa in
        [nN] ) 
        	echo "monitoring will NOT be installed."
        ;;
        * )
        	echo "monitoring WILL be installed."
        ;;
esac

apt-get update
apt-get install wget git -y


cd $cwd

apt-get install python-dev libasound2-dev python-pip memcached vlc -y

git clone https://github.com/duxingkei33/orangepi_PC_gpio_pyH3.git
cd orangepi_PC_gpio_pyH3
python orangepi_PC_gpio_pyH3/setup.py install 
cd ..

wget http://www.portaudio.com/archives/pa_stable_v19_20140130.tgz
tar -xvzf pa_stable_v19_20140130.tgz
cd portaudio
./configure && make
sudo make install
cd ..

rm -rf orangepi_PC_gpio_pyH3
rm -rf portaudio
rm -rf pa_stable_v19_20140130.tgzpa_stable_v19_20140130.tgz

pip install -r requirements.txt
touch /var/log/alexa.log

case $shairport in
        [nN] ) ;;
        * )
                echo "--building and installing shairport-sync--"
                cd /root
                apt-get install autoconf libdaemon-dev libasound2-dev libpopt-dev libconfig-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev -y
                git clone https://github.com/mikebrady/shairport-sync.git
                cd shairport-sync
                autoreconf -i -f
                ./configure --with-alsa --with-avahi --with-ssl=openssl --with-soxr --with-metadata --with-pipe --with-systemd
                make
                getent group shairport-sync &>/dev/null || sudo groupadd -r shairport-sync >/dev/null
                getent passwd shairport-sync &> /dev/null || sudo useradd -r -M -g shairport-sync -s /usr/bin/nologin -G audio shairport-sync >/dev/null
                make install
                systemctl enable shairport-sync
                cd $cwd
                rm -r /root/shairport-sync
        ;;
esac

case $monitorAlexa in
        [nN] ) 
		cp initd_alexa.sh /etc/init.d/AlexaOPi
	;;
        * )
		cp initd_alexa_monitored.sh /etc/init.d/AlexaOPi
        ;;
esac

update-rc.d AlexaOPi defaults

echo "--Creating creds.py--"
echo "Enter your Device Type ID:"
read productid
echo ProductID = \"$productid\" > creds.py

echo "Enter your Security Profile Description:"
read spd
echo Security_Profile_Description = \"$spd\" >> creds.py

echo "Enter your Security Profile ID:"
read spid
echo Security_Profile_ID = \"$spid\" >> creds.py

echo "Enter your Client ID:"
read cid
echo Client_ID = \"$cid\" >> creds.py

echo "Enter your Client Secret:"
read secret
echo Client_Secret = \"$secret\" >> creds.py

python ./auth_web.py

echo "Open http://$ip:5000"

echo "You can now reboot"
