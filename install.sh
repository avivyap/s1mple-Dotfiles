#!/bin/bash

# hecho por avivyap, :]
#setup cutre pero funcional


#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"
orangeColour="\e[38;5;208m\033[1m"
whiteColour="\e[0;97m\033[1m"
whiteUltra="\e[38;5;231m"

# Nos colocamos en la carpeta del repo para que las rutas relativas (.config, fonts, bin...) funcionen
cd "$(dirname "$0")"


trap ctrl_c INT

function ctrl_c(){

        echo -e "${redColour}[!] Saliendo.......${endColour}"
        tput cnorm
        exit 1

}

function bspwm(){

	sleep 1; clear
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing bspwm and dependences...${endColour}\n"
	sudo apt install bspwm -y > /dev/null 2>&1
	sleep 1
	sudo apt-get install libxcb-xinerama0-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-util0-dev libxcb-ewmh-dev libxcb-keysyms1-dev libxcb-shape0-dev
	sleep 1
	sudo apt install libxcb-xkb-dev
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Configurate bspwm...${endColour}\n"
	git clone https://github.com/baskerville/bspwm.git $HOME/bspwm
	sleep 1
	(cd $HOME/bspwm && make && sudo make install)
	sleep 1
	mkdir -p $HOME/.config
	mv .config/bspwm $HOME/.config/
	sleep 1

}

function sxhkd(){

	sleep 1; clear
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing sxhkd and dependences...${endColour}\n"
	sudo apt-get install libxcb1-dev libxcb-xkb-dev libxkbcommon-dev libxcb-util0-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libx11-dev pkg-config
	git clone https://github.com/baskerville/sxhkd.git $HOME/sxhkd
	sleep 1
	(cd $HOME/sxhkd && make && sudo make install)
	sleep 1
	mkdir -p $HOME/.config/sxhkd
	mv .config/sxhkdrc $HOME/.config/sxhkd/

}

function mixed_configurations(){

	sleep 1;clear
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Applying configurations...${endColour}\n"
	sleep 1
	mkdir -p ~/.config/{bspwm,sxhkd}
	# -n para no pisar los archivos propios que ya se movieron antes
	cp -n /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/
	cp -n /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/
	chmod u+x ~/.config/bspwm/bspwmrc
	chmod u+x ~/.config/bspwm/scripts/* 2>/dev/null

	mv .config/.xinitrc $HOME
}

function others(){

	sleep 1;clear
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing tools for wallpaper configuration, transparencies...${endColour}\n"
	sudo apt install feh -y > /dev/null 2>&1
	sleep 1
	sudo apt install rofi -y > /dev/null 2>&1
	sleep 1
	[ -d .config/rofi ] && mv .config/rofi $HOME/.config
	mkdir -p $HOME/.config/rofi/theme
	mv .config/Arc-Dark.rasi $HOME/.config/rofi/theme/
	sleep 1
	sudo apt install picom
	sleep 1
	mkdir -p ~/.config/picom
	cp .config/picom.conf $HOME/.config/picom.conf
	echo -e "\n${greenColour}[V]${endColour}${blueColour} Everything configured correctly${endColour}\n"
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Configuring fonts...${endColour}\n"
	sleep 1 && sudo mv fonts  /usr/local/share/ && fc-cache -fv > /dev/null 2>&1
	echo -e "\n${greenColour}[V]${endColour}${blueColour} Everything configured correctly${endColour}\n"

	#####

	mv bin ~/.config
	chmod u+x ~/.config/bin/*
	mv wallpapers $HOME/wallpaper
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing extra tools used by the configs...${endColour}\n"
	for paquete in tmux dconf-cli gnome-terminal wmname i3lock-fancy scrub psmisc fonts-cantarell fonts-unifont fonts-font-awesome; do
		sudo apt install $paquete -y > /dev/null 2>&1
	done
	[ -f .config/gnome-terminal.dconf ] && dconf load /org/gnome/terminal/legacy/ < .config/gnome-terminal.dconf
	dconf write /org/gnome/terminal/legacy/default-show-menubar false
	sleep 1; echo -e "${purpleColour}[+]${endColour}${blueColour} Installing zsh...${endColour}\n"
	sleep 1; sudo apt install zsh > /dev/null 2>&1 && echo -e "${greenColour}[V]${endColour}${blueColour} Installed correctly${endColour}"

}

function polybar(){

	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing and configuring Polybar${endColour}\n"
	sudo apt install build-essential git cmake cmake-data pkg-config python3-sphinx python3-packaging libuv1-dev libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev

	sleep 1
	sudo git clone --recursive https://github.com/polybar/polybar /opt/polybar
	sleep 1
	sudo cmake -S /opt/polybar -B /opt/polybar/build
	sleep 1
	sudo make -C /opt/polybar/build -j$(nproc)
	sleep 1
	sudo make -C /opt/polybar/build install
	mkdir -p $HOME/.config/polybar
	mv .config/polybar/config $HOME/.config/polybar/config.ini
	sed -i "s|/home/avivyap/|$HOME/|g" $HOME/.config/polybar/config.ini
	printf '%s\n' '#!/usr/bin/env bash' 'killall -q polybar' 'while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done' 'polybar parrot &' > $HOME/.config/polybar/launch.sh
	chmod u+x $HOME/.config/polybar/launch.sh
	sleep 1

	echo -e "\n${greenColour}[V]${endColour}${blueColour} Polybar successfully installed${endColour}\n"
}

function powerlevel10k(){

	sleep 1;clear
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Configuring powerlevel10k${endColour}\n"
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
	mv .config/p10k.zsh ~/.p10k.zsh
	[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
	mv .config/zshrc ~/.zshrc
	sleep 1;sudo usermod --shell "$(which zsh)" $USER
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing others tools...${endColour}\n"
	sleep 1;sudo apt install lsd >/dev/null 2>&1
	sleep 1; sudo apt-get install zsh-syntax-highlighting -y > /dev/null 2>&1
	sleep 1; sudo chown $USER:$USER /usr/share/zsh-syntax-highlighting/ -R
	sleep 1; git clone --single-branch https://github.com/gpakosz/.tmux.git ~/.tmux
	sleep 1; ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
	sleep 1; cp ~/.tmux/.tmux.conf.local ~/
	echo -e "\n${greenColour}[V]${endColour}${blueColour} TMUX Configurated${endColour}\n"
	echo -e "\n${purpleColour}[+]${endColour}${blueColour} Installing bat...${endColour}\n"
	sudo dpkg -i .config/bat_0.26.1_amd64.deb > /dev/null 2>&1

}

function main(){

	tput civis
	bspwm
	sxhkd
	mixed_configurations
	others
	polybar
	powerlevel10k
	tput cnorm
}

main
