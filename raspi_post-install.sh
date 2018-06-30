# !/bin/bash
# Raspberry post install script

# TODO: ask with dialog instead of variables

### Editable variables:
host_name=rpi
new_user=mermouy
key_map=fr-pc
timezone=/usr/share/zoneinfo/Europe/Paris
gpu_mem=16
rasp_pkgs=build-essential python-dev python-smbus python-pip git
arch_pkgs=base-devel git python-dev python-smbus python-pip

### Load layout variables
source bash_colors

### Help
help_display(){
	echo -e $c_yellow"$line_\n"$c_reset
	echo -e $b_white"Usage:\n"$c_reset$0 "[option]\n"
	echo -e $c_white"Options:\n"
	echo -e $c_green"-r "$c_reset"or "$c_green"--raspbian "$c_cyan":"$c_blue"Use this option you installed a raspbian linux distribution"
	echo -e $c_green"-a "$c_reset"or "$c_green"--archarm "$c_cyan":"$c_blue"Use this option if you installed an Arch linux Arm distribution"
	echo
	echo -e $c_yellow"$line_\n"$c_reset

}

base(){
	# Host(s) Name
	echo "${host_name}" > /etc/hostname
	echo -e $c_blue"Hostname set to $c_green$host_name"$c_reset
}

raspi(){
	# raspi-config is mostly taking care of the needed stuff
	sudo apt update && sudo apt-upgrade && sudo apt dist-upgrade
	sudo apt install $rasp_pkgs || echo -e $b_red"Error\n$c_redUnable to install packages"$c_reset
	sudo raspi-config
}

arch(){
	su && passwd
	echo -e $c_green"Setting up keyboard and locales\n"$c_reset
	loadkeys $key_map
	echo "KEYMAP=$key_map" > /etc/vconsole.conf
	echo -e $c_green"Setting up timezone to $c_cyan$time_zone\n"$c_reset
	ln -sf $time_zone /etc/localtime
	echo -e $c_green"Upgrading system & packages to latest version\n"$c_reset
	pacman-key --init && pacman-key --populate archlinuxarm || echo -e $c_red"Error while updating..."$c_reset
	pacman -Syyu
	# Adding new user
	if [ -n $new_user ];then
		echo -e $c_green"Adding new user: $c_cyan$new_user"
		useradd -m -g users -s /bin/bash -G audio,games,lp,optical,power,scanner,storage,video $new_user
		passwd $new_user
	fi
	# Adding sudo
	echo -e $c_green"Installing $c_cyansudo$c_green package, adding $c_cyansudo group$c_green, adding $c_cyan$new_user$c_green to that group"$c_reset
	pacman -S sudo
	groupadd sudo
	usermod -a -G sudo $new_user
	echo 'sudo ALL=(ALL:ALL) ALL' | EDITOR='tee -a' visudo
	# Modifying gpu-mem
	echo -e $c_green"Modifying gpu allowed memory to $c_cyan$gpu_mem"$c_reset
	sed '/gpu_mem/d' /boot/config.txt
	echo "gpu_mem=$gpu_mem" >> /boot/config.txt

	# Install hat libs
	pacman -S --needed $arch_pkgs
}

# Verify root exec
if [[ $EUID -ne 0 ]]; then
   echo -e $b_red"Ce script doit être lancé avec les droits admin !"$c_reset 1>&2
   exit 1
fi

### Verify passed Args and run
if (( $# >= 2 ));then
	echo -e $c_red"Error"\n$c_purple"This script accept only one argument"$c_reset
	exit 1
elif (( $# != 0 )) && (( $# < 2 ));then
	if [ $1 = "-h" ] || [ $1 = "--help" ];then
		help_display && exit 0
	elif [ $1 = "-r" ];then
		base &&	raspi
	elif [ $1 = "-a" ] || [ $1 = "--archarm" ];then
		base && arch
	fi
else
	echo "Not raspbian nor arch..."
fi
