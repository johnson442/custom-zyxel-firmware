
# VMG1312/8x24 Custom Firmware Build System
 
Dockerfile and scripts for creating the (old) environment required to build firmware images for Zyxel VMG1312-B10A & VMG8x24-B10A modem/routers, including helper script and patches to enable:
 
#### 1508 MTU 'baby' jumbo frames
Changes to to the ethernet driver to allow > 1500 MTU ethernet frames & changes to the PTM network driver to bring the link up with an MTU of 1508 by default.
 
#### Older telnet binary
Choice to include an older version of the telnetd binary from previous firmware before it was modified to only accept a single telnet connection.
 
#### Later adsl_phy.bin
Latest firmware from Zyxel include the A2pv6F039**v** DSL modem code, other devices with the same BCM63168 chipset have received firmware with later A2pv6F039**x1** & A2pv6F039**x6** modem code, either can be included for testing.

#### Custom commands at boot

Place holder script in /data partition run once every boot to allow persistent changes to target SNRM or line capping. See /data/boot-cmds.sh after first boot for details.
 
#### Modem stats server with logging and web interface
A small mongoose based http server with simple visualisation of real time and logged statistics avaliable by default on modem-ip:8000. 

![screen1](/stats-staging/screenshot1.png?raw=true "Stats screenshot1")

![screen2](/stats-staging/screenshot2.png?raw=true "Stats screenshot2")

48h line statistics are captured, see stats-server/stats-logging.sh for details. Information usually requiring telnet/ssh to access (e.g xdslctl output) is available via HTTP at modem-ip:8000/data, see directory listing for naming.


## Prerequisites
 
A working Docker installation.
 
If you wish you can request source package directly from Zyxel and place in the zyxel-source folder, or simply download from the releases section [here](https://github.com/johnson442/zyxel-sources/releases), see README in zyxel-sources directory.
 

## Usage
 
```
git clone https://github.com/johnson442/custom-zyxel-firmware
or
download source zip and extract.
 
cd custom-zyxel-firmware
cd zyxel-source/
Run your choice of script for fetching correct source for model
or
Extract source obtained from Zyxel here, see readme for naming

cd ../
 
docker build --tag=vmg-lucid .
docker run -it --name vmg-build -v "$(pwd)":/tmp/mount vmg-lucid
 
cd mount
./custom-build-1312.sh
or
./custom-build-8324.sh
```

Resulting firmware is located in images/ directory.

Docker commands may require sudo privilege depending on your system and SELinux enabled systems will probably require:
```
--security-opt label:disable
```
to be added to the docker run commands, eg:
```
sudo docker run -it --security-opt label:disable --name vmg-build -v "$(pwd)":/tmp/mount vmg-lucid
```

During docker image build on such systems warnings can be ignored.

To run the container again at a later date:

```
docker start -i vmg-build
```

### Disclaimer
Released [binaries](https://github.com/johnson442/custom-zyxel-firmware/releases) have been at minimum tested to boot on correct hardware, but use at your own risk. Having a serial adapter on hand is highly encouraged.

