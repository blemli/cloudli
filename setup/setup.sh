NAME="cloudli"
DESCRIPTION="a gigantic usb-drive thats always up-to-date"

echo "~~~ make installation stuff executable ~~~"
sudo chmod +x setup/*.sh

echo "~~~ turn off swapping to preserve sdcards ~~~"
sudo swapoff --all                            # swapping is stupid anyways
sudo apt autoremove -y --purge dphys-swapfile # and then we dont need the swapfile anymore
#todo: noatime

echo "~~~ add convenience aliases ~~~"
echo "alias restart='sudo service $NAME restart && sudo service avahi-daemon restart'" >> ~/.bash_profile
echo "alias follow='journalctl -u $NAME --follow'" >> ~/.bash_profile
echo "alias errors='journalctl -u $NAME -b -p emerg..err'" >> ~/.bash_profile
echo "alias update='cd /opt/$NAME && setup/update.sh'" >> ~/.bash_profile
echo "alias status='service $NAME status'" >> ~/.bash_profile
echo "alias disable='sudo service $NAME stop && sudo systemctl disable $NAME'" >> ~/.bash_profile
echo "alias enable='sudo systemctl enable $NAME && sudo service start $NAME'" >> ~/.bash_profile


echo "~~~ install basic tools ~~~"
sudo apt install -y dnsutils vim git tldr python3-pip bat tmux iptables

echo "~~~ disable password login via ssh ~~~"
#todo

echo "~~~ set custom login banner ~~~"
sudo apt install -y figlet
figlet $NAME >>motd
echo "by Problemli" >>motd
echo " " >>motd
echo " >> $DESCRIPTION << " >>motd
echo " " >>motd
echo " " >>motd
echo "   restart: sudo service $NAME restart" >>motd
echo "   disable: sudo systemctl disable $NAME" >>motd
echo "   live logs: journalctl -u $NAME --follow" >>motd
echo "   errors since last boot: journalctl -u $NAME -b -p emerg..err" >>motd
echo " " >>motd
echo " " >>motd
sudo cp -f motd /etc/motd
rm motd                   # clean up after ourselves
sudo apt remove -y figlet # clean up after ourselves

echo "~~~ change directory after connecting ~~~"
echo "cd /opt/$NAME" >> ~/.bash_profile
echo "source .venv/bin/activate" >> ~/.bash_profile

echo "~~~ redirect requests on port 80 to 8080 ~~~~"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt install -y iptables-persistent

echo "~~~ avoid writing syslog ~~~"
sudo mkdir /etc/rsyslog.d
echo ":programname, isequal, \"$NAME\" stop" | sudo tee -a /etc/rsyslog.d/filter-$NAME.conf
echo ":programname, isequal, \"$NAME-admin\" stop" | sudo tee -a /etc/rsyslog.d/filter-$NAME-admin.conf

echo "~~~ install venv ~~~"
python3 -m venv .venv
source .venv/bin/activate
python3 -m ensurepip

#curl -LsSf https://astral.sh/uv/install.sh | sh
#source $HOME/.cargo/env
#uv venv
#source .venv/bin/activate

echo "~~~ install nextcloud cli ~~~"
sudo apt install nextcloud-desktop-cmd

echo "~~~ install elecrow mini pc case oled & shutdown button ~~~"
git clone https://github.com/Elecrow-RD/Small-Mini-PC-Case.git ~/Small-Mini-PC-Case
sudo cp ~/Small-Mini-PC-Case/Raspberry\ Pi\ 5/rpi5-oled.py /usr/local/bin/rpi5-oled.py
sudo cp ~/Small-Mini-PC-Case/Raspberry\ Pi\ 5/rpi5-oled.service /etc/systemd/system/rpi5-oled.service
sudo cp ~/Small-Mini-PC-Case/Raspberry\ Pi\ 5/shutdown.py /usr/local/bin/shutdown.py
sudo cp ~/Small-Mini-PC-Case/Raspberry\ Pi\ 5/rcshutdown.service /etc/systemd/system/rcshutdown.service
sudo cp ~/Small-Mini-PC-Case/Raspberry\ Pi\ 5/rc.shutdown /etc/rc.shutdown
sudo chmod +x /usr/local/bin/rpi5-oled.py
sudo apt-get install -y python3-psutil python3-smbus
sudo systemctl enable rpi5-oled.service
sudo systemctl start rpi5-oled.service
sudo chmod 777 /usr/local/bin/shutdown.py
sudo chmod 777 /etc/systemd/system/rcshutdown.service
sudo chmod 777 /etc/rc.shutdown
sudo systemctl enable rcshutdown.service
sudo systemctl start rcshutdown.service
rm -rf ~/Small-Mini-PC-Case

echo "~~~ install  ~~~"
setup/install-$NAME.sh
