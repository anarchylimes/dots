#!/usr/bin/env bash
# author daniel neemann (@zzzeyez)
# symlink my dotfiles
# get dotfiles directory, even if this script is symlinked

wallpaper='/tmp/wallpaper.png'

setup() {
	# get absolute path of dots folder
	source="${BASH_SOURCE[0]}"
	while [ -h "$source" ]; do
		dots="$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )"
		source="$(readlink "$source")"
		[[ $source != /* ]] && source="$dots/$source"
	done
	dots="$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )"
	if [[ "$notify" ]] ; then
		notify-send "cleaning and updating system.."
	fi
	# log in to sudo and stay there
	#if [[ "$sudo" ]] ; then
	#	sudo -v
	#while true; do sudo -n true; sleep 60; kill -0 "$$"\
	#	|| exit; done 2>/dev/null &
	#fi
}

screenshot() {
	# screenshot
	screencapture "$dots/screenshot.png"
	# wallpaper
	cp "$wallpaper" "$dots/wallpaper.png"
	# wal colors
	cp "${HOME}/.cache/wal/colors.json" "$dots/colors.json"
	# notify
	if [[ "$notify" ]] ; then
		notify-send -m "dotfiles updated" -i "$dots/screenshot.png"
	fi
	}

makebar() {
	# color escapes
	red="\e[31m"
	grn="\e[32m"
	ylw="\e[33m"
	blu="\e[34m"
	pur="\e[35m"
	cyn="\e[36m"
	gry="\e[90m"
	rst="\e[0m"
	bar="▔▔▔▔▔▔"
	bar="$red$bar$grn$bar$ylw$bar$blu$bar$pur$bar$cyn$bar$rst"
	clear
}

brewinstall() {
	printf "\nhomebrew packages\n$bar\n"
	printf "\ndo you want to install brew packages?\n\n(y/n) "
	read -r response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		if [[ ! "$(command -v brew)" ]] ; then
			printf "\nhomebrew is not installed.  install?\n\n(y/n) "
			read -r response
##########################################################################################
			if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
				printf "\ninstalling homebrew..\n\n"
				/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
				BREW_PREFIX=$(brew --prefix)
				printf "\nhomebrew installed\n\n"
			fi
#############################################################################################
		else
			printf "\nupdating homebrew..\n\n"
			brew update
			brew upgrade
			printf "\nhomebrew updated\n\n"
		fi
		brew_packages=(); while read -r; do brew_packages+=("$REPLY"); done < "$dots/install/brew_packages"
		for package in "${brew_packages[@]}"
		do
			if [[ ! "$package" == \#* ]] && [[ ! -z "$package" ]] ; then
				printf "\nhomebrew packages\n$bar\n"
				printf "\n$package\n\n(y/n) "
				read -r response
				if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
					bash $package
					echo ""
				fi
			fi
		done
		brew cleanup
	fi
}

gitclone() {
	printf "\ngithub\n$bar\n"
	printf "\ndo you want to clone your git repos?\n\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ ! "$test" ]] ; then
					bash "$dots/install/git_clones" &&
					echo "repos cloned"
				else
					echo "repos cloned"
				fi
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo 'enter yes/no'
			;;
		esac
	done
}

pythonpackages() {
	printf "\npython\n$bar\n"
	printf "\ndo you want to install python packages?\n\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ ! "$test" ]] ; then
					pip3 install pywal &&
					echo "pywal installed"
					pip install Mopidy-Tidal &&
					echo "mopidy-tidal installed"
				else
					echo "pywal installed"
					echo "mopidy-tidal installed"
				fi
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo 'enter yes/no'
			;;
		esac
	done
}

zsh_plugins() {
	printf "\noh-my-zsh\n$bar\n"
	printf "\ndo you want to install oh-my-zsh + plugins?\n"
	zsh_plugins=(); while read -r; do zsh_plugins+=("$REPLY"); done < "$dots/install/zsh_plugins"
	printf "\n(y/n)"
	read -r response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		gitpre='https://github.com'
		zshdir="${HOME}/.oh-my-zsh/custom/plugins"
		for repo in "${zsh_plugins[@]}"
		do
			if [[ ! "$repo" = \#* ]] && [[ ! -z "$repo" ]] ; then
				printf "\noh-my-zsh\n$bar\n"
				printf "\ninstall $repo?\n\n(y/n) "
				read -r response
				if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
					if [[ ! -d "$zshdir/${repo##*/}" ]] ; then
						echo ""
						git clone "$gitpre/$repo.git" "$zshdir/${repo##*/}"
					else
						echo ""
						echo "$repo exists, skipping.."
					fi
				fi
			fi
		done
		echo ""
	fi
}

shell() {
	query="$(cat /etc/shells | grep /usr/local/bin/zsh)"
		if [[ -z "$query" ]] ; then
			printf "\nshell\n$bar\n"
			printf "\nswitch to zsh and brew-installed bash?\n\n$paths\n\n"
			while true
			do
			read -p "(y/n) " yn
				case $yn in
					[Yy]*)
						if [[ ! "$test" ]] ; then
							sudo sh -c 'echo /usr/local/bin/zsh >> /etc/shells && chsh -s /usr/local/bin/zsh'
							if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
								echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
								chsh -s "${BREW_PREFIX}/bin/bash";
							fi;
							echo "shell changed to brew-installed bash and zsh"
						else
							echo "shell changed to brew-installed bash and zsh"
						fi
						break
					;;
					[Nn]*)
						break
					;;
					*)
						echo 'enter yes/no'
					;;
				esac
			done
		fi
	unset query
}

paths() {
	if [[ ! -f "/etc/paths.d/paths" ]] ; then
		paths="/usr/bin/local\n${HOME}/scripts/bin\n${HOME}/.bin\n$(brew --prefix coreutils)/libexec/gnubin"
		printf "\npath\n$bar\n"
		printf "\ndo you want to export these to your path?\n\n$paths\n\n"
		while true
		do
		read -p "(y/n) " yn
			case $yn in
				[Yy]*)
					if [[ ! "$test" ]] ; then
						sudo echo "$paths" >> /etc/paths.d/paths &&
						echo "paths updated"
					else
						echo "paths updated"
					fi
					break
				;;
				[Nn]*)
					break
				;;
				*)
					echo 'enter yes/no'
				;;
			esac
		done
	fi
}

clearhome() {
	printf "\nhome\n$bar\n"
	printf "\ndo you want to delete your home?\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				# delete everything in home, with exceptions in save_home
				remove="${HOME}"
				save_home=(); while read -r; do save_home+=("$REPLY"); done < \
					"$dots/install/save_home"
				remove "${save_home[@]}"
				# recreate folders in home, defined in recreate_home
				make_dir=(); while read -r; do make_dir+=("$REPLY"); done < \
					"$dots/install/make_directories" && 
				recreate "${make_dir[@]}"
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo "enter yes/no"
			;;
		esac
	done
}

# called by clearhome()
recreate() {
	printf "\nmake directories\n$bar\n"
	printf "$gry%s$rst\n" "${make_dir[@]}"
	printf "\ncreate these directories if they are non-existant?\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)	 
				if [[ "$test" ]] ; then
					printf "\ndirectories created\n"
				else
					cd "${HOME}" &&
					mkdir -p "${make_dir[@]}" &&
					printf "\ndirectories created\n"
				fi
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo "enter yes/no"
			;;
		esac
	done
}

clearlibrary() {
	printf "\nLibrary\n$bar\n"
	printf "\ndo you want to delete ~/Library?  restart required\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				library="on"
				remove="${HOME}/Library"
				save_library=(); while read -r; do save_library+=("$REPLY"); done < \
					"$dots/install/save_library" && 
				remove "${save_library[@]}"
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo "enter yes/no"
			;;
		esac
	done
}

# called by clearhome() and clearlibrary()
remove() {
	deleted="$cyn$(find "$remove" -maxdepth 1 -not -name "$1" -not -name "$2" -not -name "$3"\
		-not -name "$4" -not -name "$5" -not -name "$6"\
		-not -name "$7" -not -name "$8" -not -name "$9" -not -name "." -not -name ".."\
		| awk '{system ("echo \""$0"\"")}')$rst"
	printf "\ndelete these:\n$bar\n$deleted\n\nand keep these:\n$bar\n"
	printf "$gry%s$rst\n" "$@"
	printf "\nis this really what you want?\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
			if [[ "$test" ]] ; then
				printf "\nfinished\n"
			elif [[ "$library" ]] ; then
				find "$remove" -maxdepth 1 -not -name "$1" -not -name "$2" -not -name "$3"\
					-not -name "$4" -not -name "$5" -not -name "$6"\
					-not -name "$7" -not -name "$8" -not -name "$9" -not -name "." -not -name ".."\
					| awk '{system ("sudo rm -rf \""$0"\"")}' &&
				printf "\nfinished\n"
			else
				find "$remove" -maxdepth 1 -not -name "$1" -not -name "$2" -not -name "$3"\
					-not -name "$4" -not -name "$5" -not -name "$6"\
					-not -name "$7" -not -name "$8" -not -name "$9" -not -name "." -not -name ".."\
					| awk '{system ("sudo rm -rf \""$0"\"")}' &&
				printf "\nfinished!!\n"
			fi
			break
			;;
			[Nn]*)
			break
			;;
			*)
			echo "enter yes/no"
			;;
		esac
	done
}

dotfiles() {
	printf "\ndotfiles\n$bar\n"
	printf "\ndo you want to symlink your dotfiles?\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ ! "$test" ]] ; then
					symlinkdots
				fi
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo 'enter yes/no'
			;;
		esac
	done
}

# updates links
# dots/$1 to ~/$2
symlinkdots() {
	# first arg is dots/$1 and second is ~/$2
	# bin
	title='bin'
	dot 'bin' '.bin'
	# chunkwm + skhd
	title='chunkwm + skhd'
	dot 'chunkwm/chunkwmrc' '.chunkwmrc'
	dot 'chunkwm/skhdrc' '.skhdrc'
	# irssi
	#title='irssi'
	#dot 'irssi' '.irssi'
	# iterm2
	title='iterm2'
	dot 'iterm2/com.googlecode.iterm2.plist' 'Library/Preferences/com.googlecode.iterm2.plist'
	# ncmpcpp
	title='ncmpcpp + mpd'
	dot 'ncmpcpp' '.ncmpcpp'
	dot 'ncmpcpp/mopidy.conf' '.config/mopidy/mopidy.conf'
	# neovim
	title='neovim'
	dot 'nvim' '.config/nvim'
	# tmux
	title='tmux'
	dot 'tmux/tmux.conf' '.tmux.conf'
	dot 'tmux/tmux-better-mouse-mode' '.config/tmux-better-mouse-mode'
	# wal
	title='wal'
	dot 'wal' '.config/wal'
	# weechat
	title='weechat'
	dot 'weechat' '.weechat'
	# oh-my-zsh
	title='oh-my-zsh'
	dot 'oh-my-zsh/themes' '.oh-my-zsh/custom/themes'
	dot 'oh-my-zsh/zshrc' '.zshrc'
	# new-roses
	title='new-roses'
	dot 'new-roses' '.config/new-roses'
	# git
	title='git'
	dot 'git/gitignore_global' '.gitignore_global'
	dot 'git/gitconfig' '.gitconfig'
	# fonts
	title='fonts'
	dot "fonts" "Library/fonts"
	# pecan + xanthia
	title='pecan + xanthia'
	mkdir -p "Library/Application Support/Übersicht/widgets" &>/dev/null
	dot '../pecan' "Library/Application Support/Übersicht/widgets/pecan"
	dot '../xanthia' "Library/Application Support/Übersicht/widgets/xanthia"
	# this file
	title='dots'
	dot 'dots.sh' '../../usr/local/bin/dots'
	if [[ "$notify" ]] ; then
		ps cax | grep bersicht > /dev/null
		if [ $? -eq 0 ] ; then
			ubersicht=$(ps cax | grep bersicht | awk '{print $1}')
			kill $ubersicht
			open -a Übersicht
			sleep 2s
	fi
fi

}

# move and overwrite old dots with verification prompt
dot() {
	new="$dots/$1"
	old="${HOME}/$2"
	printf "\n$title\n$bar\n$new $red->$rst\n$old\n"
	while true
	do
		read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ -d "$old" ]] || [[ -f "$old" ]] ; then
					printf "\n$old exists.. overwrite?\n"
					while true
					do
						read -p "(y/n) " yn
						case $yn in
							[Yy]*)
								if [[ "$test" ]] ; then
									printf "\nremoved $old\n"
								else
									rm -rf "$old" &&
									printf "\nremoved $old\n"
								fi
								break
							;;
							[Nn]*)
								printf "\nskipping..\n"
								break
							;;
							*)
								echo "enter yes/no"
							;;
						esac
					done
				else
					printf "\n$old not found. creating..\n"
				fi
				if [[ "$test" ]] ; then
					echo "linked $new to $old"
				else
					ln -sf "$new" "$old" &&
					echo "linked $new to $old"
				fi
				break
			;;
			[Nn]* )
			echo "skipping.."
			break
			;;
			* )
				echo 'enter yes/no'
			;;
		esac
	done
}

macos_settings() {
	printf "\nmacos settings\n$bar\n"
	printf "\ndo you want to apply mac settings?\n"
	read -r response
	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
		macos_settings=(); while read -r; do macos_settings+=("$REPLY"); done < "$dots/install/macos_settings"
		for setting in "${macos_settings[@]}"
		do
			if [[ ! "$setting" == \#* ]] && [[ ! -z "$setting" ]] ; then
				if [[ "$setting" == title* ]] ; then
					bash $setting
					printf "\n$title\n$bar\n"
				elif [[ "$setting" == message* ]] ; then
					bash $setting
					printf "\n$message\n$bar\n"
				else
					printf "\n$setting\n\n(y/n) "
					read -r response
					if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
						bash $setting
						echo ""
					fi
				fi
			fi
		done
	fi
}

brewupdate() {
	printf "\nbrew update\n$bar\n"
	printf "\ndo you want to update homebrew?\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ ! "$test" ]] ; then
					brew update
					brew upgrade
					brew cleanup
				fi
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo 'enter yes/no'
			;;
		esac
	done
}

brewservices() {
	printf "\nhomebrew services\n$bar\n"
	printf "\ndo you want to auto start mopidy, skhd and chunkwm?\\n"
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ ! "$test" ]] ; then
					brew services start skhd &>/dev/null &&
					echo "skhd started" 
					brew services start chunkwm &>/dev/null &&
					echo "chunkwm started"
					brew services start mopidy &>/dev/null &&
					echo "mopidy started"
				fi
				break
			;;
			[Nn]*)
				break
			;;
			*)
				echo 'enter yes/no'
			;;
		esac
	done
}

finished() {
	printf "\nfinished\n$bar\n"
	printf "if ~/Library was removed, reapply macos settings after reboot\n"
	printf "most settings won't be applied until after rebooting\n"
	printf "do you want to reboot right now?\n"
	if [[ "$notify" ]] ; then
		notify-send "system upgraded and cleaned"
	fi
	while true
	do
	read -p "(y/n) " yn
		case $yn in
			[Yy]*)
				if [[ ! "$test" ]] ; then
					if [[ ! "$noninteractive" ]] ; then
						sudo reboot
						echo "rebooting.."
					else
						printf "\nnon-interactive mode.. skipping reboot\n"
					fi
					exit
				else
					echo "rebooting.."
					exit
				fi
			;;
			[Nn]*)
				echo "exiting.."
				exit
			;;
			*)
				echo 'enter yes/no'
			;;
		esac
	done
}

flags() {
	while getopts snyx opt; do
		case $opt in
			s)
			screenshot
			exit
			;;
			n)
			notify="on"
			;;
			y)
			auto="on"
			;;
			x)
			test="on"
			;;
			*)
			echo '-u to save screen shot and wal colors'
			echo '-n to notify-send when done'
			echo '-y for non-interactive mode'
			echo '-x to test without affecting system'
			exit
			;;
		esac
	done
}

setup
makebar
flags "$@"
if [[ "$auto" ]] ; then
	yes | clearhome
	yes | dotfiles
	yes | macos_settings
	yes | brewupdate
else
	brewinstall
	gitclone
	pythonpackages
	zsh_plugins
	paths
	shell
	clearhome
	clearlibrary
	dotfiles
	macos_settings
	brewservices
	finished
fi

# todo

# touch .hushlogin

# map caps lock -> alt (current method is reset on reboot)

# echo path to skhd plist
# gsed -i 's/:\/sbin/:\/sbin:\/Users\/zzzeyez\/.bin:\/Users\/zzzeyez\/scripts\/bin/g' skhd.plist 

# echo paths to /etc/paths.d/paths

# get skhd to access bin (sometimes it doesn't) 
# or was this because my .scss files sourced invalid paths?
# wallpaper is not working, but wal, togglebar and colorlovers are?

# link colorlovers and new-roses pecanstyle

# zsh-git-prompt is buggy

# gray highlught isn't working now? the accents are..

# i could simplify this script by eliminating redundant functions if you can store commands in arrays

# apply `pollen` as safari home page

#process array with `find` better than $1, $2, etc
