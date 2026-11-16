#!/bin/bash

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

cd "$(dirname "$0")" || exit 1

LOG="$HOME/install-dotfiles.log"
BACKUP="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
FAILED_PACKAGES=""
MISSING_FILES=""
WARNINGS=0
PICOM_ON="${PICOM_ON:-ask}"
ARCH=""
VIRT="none"
export DEBIAN_FRONTEND=noninteractive

: > "$LOG"


trap ctrl_c INT
trap 'tput cnorm 2>/dev/null' EXIT

function ctrl_c(){

        echo -e "\n${redColour}[!] Exiting.......${endColour}"
        tput cnorm
        exit 1

}

function log(){

	echo "[$(date +%T)] $*" >> "$LOG"

}

function is_installed(){

	dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"

}

function apt_install(){

	sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"

}

function install_packages(){

	local pending=() pkg bad=""

	for pkg in "$@"; do
		is_installed "$pkg" || pending+=("$pkg")
	done
	[ ${#pending[@]} -eq 0 ] && return 0

	log "apt-get install ${pending[*]}"
	if apt_install "${pending[@]}" >> "$LOG" 2>&1; then
		return 0
	fi
	for pkg in "${pending[@]}"; do
		if ! apt_install "$pkg" >> "$LOG" 2>&1; then
			bad="$bad $pkg"
			log "Could not install: $pkg"
		fi
	done
	if [ -n "$bad" ]; then
		FAILED_PACKAGES="$FAILED_PACKAGES$bad"
		WARNINGS=$((WARNINGS + 1))
		return 1
	fi
	return 0

}

function step(){

	local text="$1" rc before
	shift
	echo -en "  ${blueColour}$(printf '%-46s' "$text")${endColour}"
	log "=== $text"
	before=$WARNINGS
	"$@" >> "$LOG" 2>&1
	rc=$?
	if [ "$rc" -ne 0 ]; then
		echo -e "${redColour}failed${endColour}"
		log "Step failed: $text"
		WARNINGS=$((WARNINGS + 1))
	elif [ "$WARNINGS" -gt "$before" ]; then
		echo -e "${yellowColour}warnings${endColour}"
	else
		echo -e "${greenColour}ok${endColour}"
	fi
	return $rc

}

function deploy(){

	local source="$1" target="$2" rel

	if [ ! -e "$source" ]; then
		MISSING_FILES="$MISSING_FILES $source"
		WARNINGS=$((WARNINGS + 1))
		log "Not found in the repo: $source"
		return 1
	fi
	if [ -e "$target" ] || [ -L "$target" ]; then
		rel="${target#$HOME/}"
		mkdir -p "$BACKUP/$(dirname "$rel")"
		mv "$target" "$BACKUP/$rel"
		log "Backup: $target -> $BACKUP/$rel"
	fi
	mkdir -p "$(dirname "$target")"
	cp -r "$source" "$target"
	log "Deployed: $source -> $target"

}

function detect_environment(){

	if ! type -P apt-get > /dev/null; then
		echo -e "\n${redColour}[!] This script needs apt (Parrot, Debian, Kali, Ubuntu...)${endColour}\n"
		exit 1
	fi
	if [ "$EUID" -eq 0 ]; then
		echo -e "\n${redColour}[!] Do not run it as root: run it with your normal user (it uses sudo when it is needed)${endColour}\n"
		exit 1
	fi
	if ! type -P sudo > /dev/null; then
		echo -e "\n${redColour}[!] sudo is not installed${endColour}\n"
		exit 1
	fi
	if [ ! -d .config ] || [ ! -d bin ]; then
		echo -e "\n${redColour}[!] Run the script from the repo folder (.config and bin were not found)${endColour}\n"
		exit 1
	fi

	[ -f /etc/os-release ] && . /etc/os-release
	ARCH=$(dpkg --print-architecture 2>/dev/null)
	VIRT=$(systemd-detect-virt 2>/dev/null)
	[ -z "$VIRT" ] && VIRT="none"

	echo -e "\n${purpleColour}[+]${endColour}${blueColour} ${PRETTY_NAME:-unknown system} | $ARCH | virtualization: $VIRT${endColour}"
	echo -e "${grayColour}    Details are saved in $LOG${endColour}\n"
	log "Environment: ${PRETTY_NAME:-?} arch=$ARCH virt=$VIRT user=$USER"
	sudo -v || exit 1

}

function decide_picom(){

	if [ "$PICOM_ON" = "ask" ]; then
		PICOM_ON=1
		if [ "$VIRT" != "none" ] && [ -t 0 ]; then
			echo -e "${yellowColour}[?]${endColour}${blueColour} Virtual machine detected ($VIRT): picom (transparencies) can cause graphic glitches in some of them.${endColour}"
			read -r -p "    Enable picom? [Y/n] " answer
			echo
			case "$answer" in
				n|N|no|NO) PICOM_ON=0 ;;
			esac
		fi
	fi
	log "picom enabled=$PICOM_ON"

}

function update_lists(){

	sudo env DEBIAN_FRONTEND=noninteractive apt-get update -qq

}

function compile(){

	local name="$1" url="$2" utildev="libxcb-util-dev"

	apt-cache show libxcb-util-dev > /dev/null 2>&1 || utildev="libxcb-util0-dev"
	install_packages build-essential git pkg-config libxcb1-dev libxcb-xkb-dev libxkbcommon-dev "$utildev" libxcb-keysyms1-dev libxcb-xinerama0-dev libxcb-icccm4-dev libxcb-randr0-dev libxcb-ewmh-dev libxcb-shape0-dev libx11-dev
	[ -d "$HOME/$name" ] || git clone "$url" "$HOME/$name" || return 1
	(cd "$HOME/$name" && make && sudo make install)

}

function bspwm(){

	install_packages bspwm
	if ! type -P bspwm > /dev/null; then
		log "bspwm is not available with apt, compiling it"
		compile bspwm https://github.com/baskerville/bspwm.git || return 1
	fi
	deploy .config/bspwm $HOME/.config/bspwm

}

function sxhkd(){

	install_packages sxhkd
	if ! type -P sxhkd > /dev/null; then
		log "sxhkd is not available with apt, compiling it"
		compile sxhkd https://github.com/baskerville/sxhkd.git || return 1
	fi
	deploy .config/sxhkdrc $HOME/.config/sxhkd/sxhkdrc

}

function mixed_configurations(){

	mkdir -p ~/.config/{bspwm,sxhkd}
	cp -n /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/ 2>/dev/null
	cp -n /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/ 2>/dev/null
	chmod u+x ~/.config/bspwm/bspwmrc
	chmod u+x ~/.config/bspwm/scripts/* 2>/dev/null

	if [ "$PICOM_ON" -eq 0 ]; then
		sed -i 's/^\(sleep 2 && picom -b &\)/#\1/' ~/.config/bspwm/bspwmrc
		log "picom disabled in bspwmrc"
	fi

	deploy .config/.xinitrc $HOME/.xinitrc

}

function desktop_tools(){

	install_packages feh rofi picom
	[ -d .config/rofi ] && deploy .config/rofi $HOME/.config/rofi
	deploy .config/Arc-Dark.rasi $HOME/.config/rofi/theme/Arc-Dark.rasi
	deploy .config/picom.conf $HOME/.config/picom.conf
	if [ -f $HOME/.config/picom.conf ]; then
		grep -q '^backend' $HOME/.config/picom.conf || printf '\nbackend = "xrender";\n' >> $HOME/.config/picom.conf
		if [ "$VIRT" != "none" ]; then
			grep -q '^vsync' $HOME/.config/picom.conf || printf 'vsync = false;\n' >> $HOME/.config/picom.conf
		fi
	fi
	deploy bin $HOME/.config/bin
	chmod u+x ~/.config/bin/* 2>/dev/null
	deploy wallpapers $HOME/wallpaper

}

function fonts(){

	if [ -d fonts ]; then
		sudo mkdir -p /usr/local/share/fonts/hack-nerd && sudo cp -r fonts/. /usr/local/share/fonts/hack-nerd/ && sudo fc-cache -f
	else
		MISSING_FILES="$MISSING_FILES fonts"
		WARNINGS=$((WARNINGS + 1))
		return 1
	fi

}

function terminal_and_extras(){

	local terminal
	install_packages tmux dconf-cli mate-terminal wmname i3lock-fancy scrub psmisc fonts-cantarell fonts-unifont fonts-font-awesome

	case "$VIRT" in
		vmware) install_packages open-vm-tools-desktop ;;
		oracle) install_packages virtualbox-guest-x11 ;;
		kvm|qemu) install_packages spice-vdagent qemu-guest-agent ;;
	esac

	if ! gnome-terminal --version 2>/dev/null | grep -qi mate; then
		terminal=$(type -P mate-terminal || type -P x-terminal-emulator)
		[ -n "$terminal" ] && sudo ln -sf "$terminal" /usr/local/bin/gnome-terminal
	fi
	[ -f .config/mate-terminal.dconf ] && dconf load /org/mate/terminal/ < .config/mate-terminal.dconf
	return 0

}

function polybar(){

	install_packages polybar
	if ! type -P polybar > /dev/null; then
		log "polybar is not available with apt, compiling it"
		local utildev="libxcb-util-dev"
		apt-cache show libxcb-util-dev > /dev/null 2>&1 || utildev="libxcb-util0-dev"
		install_packages build-essential git cmake cmake-data pkg-config python3-sphinx python3-packaging libuv1-dev libcairo2-dev libxcb1-dev "$utildev" libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-cursor-dev libxcb-xkb-dev libxcb-xrm-dev
		[ -d /opt/polybar ] || sudo git clone --recursive https://github.com/polybar/polybar /opt/polybar || return 1
		sudo cmake -S /opt/polybar -B /opt/polybar/build || return 1
		sudo make -C /opt/polybar/build -j$(nproc) || return 1
		sudo make -C /opt/polybar/build install || return 1
	fi

	deploy .config/polybar/config $HOME/.config/polybar/config
	sed -i "s|/home/avivyap/|$HOME/|g" $HOME/.config/polybar/config
	if [ "$PICOM_ON" -eq 0 ]; then
		sed -i 's/^;pseudo-transparency = true/pseudo-transparency = true/' $HOME/.config/polybar/config
	fi
	printf '%s\n' '#!/usr/bin/env bash' 'killall -q polybar' 'while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done' 'polybar -l info -c $HOME/.config/polybar/config parrot >> /tmp/polybar.log 2>&1 &' > $HOME/.config/polybar/launch.sh
	chmod u+x $HOME/.config/polybar/launch.sh

}

function powerlevel10k(){

	install_packages zsh lsd zsh-syntax-highlighting
	[ -d ~/powerlevel10k ] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k || { FAILED_PACKAGES="$FAILED_PACKAGES powerlevel10k(git)"; WARNINGS=$((WARNINGS + 1)); }
	deploy .config/p10k.zsh $HOME/.p10k.zsh
	deploy .config/zshrc $HOME/.zshrc
	sudo usermod --shell "$(type -P zsh)" "$USER"
	sudo chown -R "$USER":"$USER" /usr/share/zsh-syntax-highlighting/ 2>/dev/null
	return 0

}

function tmux_config(){

	[ -d ~/.tmux ] || git clone --single-branch https://github.com/gpakosz/.tmux.git ~/.tmux || { FAILED_PACKAGES="$FAILED_PACKAGES oh-my-tmux(git)"; WARNINGS=$((WARNINGS + 1)); return 1; }
	ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
	[ -f ~/.tmux.conf.local ] || cp ~/.tmux/.tmux.conf.local ~/ 2>/dev/null
	return 0

}

function update_script(){

	[ -d ~/.actu ] || git clone --depth=1 https://github.com/avivyap/.actu.git ~/.actu || { FAILED_PACKAGES="$FAILED_PACKAGES .actu(git)"; WARNINGS=$((WARNINGS + 1)); return 1; }
	ln -sf ~/.actu/actualizar.sh ~/.actu.sh
	chmod u+x ~/.actu/actualizar.sh

}

function install_bat(){

	type -P bat > /dev/null && return 0
	if [ "$ARCH" = "amd64" ] && [ -f .config/bat_0.26.1_amd64.deb ]; then
		sudo dpkg -i .config/bat_0.26.1_amd64.deb
	else
		install_packages bat
		[ -x /usr/bin/batcat ] && [ ! -e /usr/bin/bat ] && sudo ln -sf /usr/bin/batcat /usr/bin/bat
	fi

}

function verification(){

	local bad=0 total=0 failed_list=""

	chk(){
		local description="$1"
		shift
		total=$((total + 1))
		if "$@" > /dev/null 2>&1; then
			log "OK: $description"
		else
			log "FAILED: $description"
			failed_list="$failed_list\n      - $description"
			bad=$((bad + 1))
		fi
	}

	for program in bspwm sxhkd picom polybar rofi feh zsh tmux lsd bat mate-terminal i3lock-fancy; do
		chk "program: $program" type -P "$program"
	done
	chk "bspwmrc" test -f ~/.config/bspwm/bspwmrc
	chk "sxhkdrc" test -f ~/.config/sxhkd/sxhkdrc
	chk "picom.conf" test -f ~/.config/picom.conf
	chk "polybar config" test -f ~/.config/polybar/config
	chk "polybar launch.sh" test -x ~/.config/polybar/launch.sh
	chk "rofi theme" test -f ~/.config/rofi/theme/Arc-Dark.rasi
	chk "scripts in ~/.config/bin" test -x ~/.config/bin/ethernet.sh
	chk "wallpaper used by bspwmrc" bash -c 'f=$(grep -o "wallpaper/[^ ]*" ~/.config/bspwm/bspwmrc | head -1); test -n "$f" && test -f ~/"$f"'
	chk "Hack Nerd Font" bash -c 'fc-list | grep -qi "hack nerd"'
	chk ".zshrc and .p10k.zsh" bash -c 'test -f ~/.zshrc && test -f ~/.p10k.zsh'
	chk "powerlevel10k" test -d ~/powerlevel10k
	chk "zsh as default shell" bash -c 'getent passwd "$USER" | grep -q "zsh$"'
	chk "update script ~/.actu.sh" test -e ~/.actu.sh
	chk "gnome-terminal command is MATE Terminal" bash -c 'gnome-terminal --version 2>&1 | grep -qi mate'

	echo
	if [ "$bad" -eq 0 ] && [ -z "$FAILED_PACKAGES" ] && [ -z "$MISSING_FILES" ]; then
		echo -e "${greenColour}[V]${endColour}${blueColour} Done: $total/$total checks passed.${endColour}"
	else
		echo -e "${yellowColour}[!]${endColour}${blueColour} Done with problems ($((total - bad))/$total checks passed):${endColour}"
		[ "$bad" -gt 0 ] && echo -e "    ${yellowColour}Failed checks:${endColour}$failed_list"
		[ -n "$FAILED_PACKAGES" ] && echo -e "    ${yellowColour}Packages not installed:${endColour}$FAILED_PACKAGES"
		[ -n "$MISSING_FILES" ] && echo -e "    ${yellowColour}Not found in the repo:${endColour}$MISSING_FILES"
	fi
	[ -d "$BACKUP" ] && echo -e "${grayColour}    Copy of what was replaced: $BACKUP${endColour}"
	echo -e "${grayColour}    Log: $LOG${endColour}"
	echo -e "\n${blueColour}[i] Restart bspwm (bspc wm -r) or log out and in again.${endColour}\n"

}

function main(){

	clear
	detect_environment
	decide_picom
	step "Updating package lists" update_lists
	step "bspwm" bspwm
	step "sxhkd" sxhkd
	step "Base configuration" mixed_configurations
	step "Wallpapers, rofi, picom, scripts" desktop_tools
	step "Fonts" fonts
	step "Terminal and extra tools" terminal_and_extras
	step "polybar" polybar
	step "zsh, powerlevel10k" powerlevel10k
	step "tmux" tmux_config
	step "bat" install_bat
	step "Update script" update_script
	verification
}

main
