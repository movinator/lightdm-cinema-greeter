# -*- 
#
lightdm-cinema-greeter_VALAFLAGS = \
	--pkg gtk+-3.0 \
	--pkg liblightdm-gobject-1 \
	-X -DGETTEXT_PACKAGE="lightdm-cinema-greeter" \
	--pkg gio-2.0 \
	--pkg pango

lightdm-cinema-greeter:		lightdm-cinema-greeter.vala
	valac $(lightdm-cinema-greeter_VALAFLAGS) lightdm-cinema-greeter.vala

data/lightdm-cinema-greeter.mo:		data/de_DE.po
	msgfmt -o data/lightdm-cinema-greeter.mo data/de_DE.po

install:		lightdm-cinema-greeter data/lightdm-cinema-greeter.mo
	mkdir /usr/share/lightdm-cinema-greeter.vala
	mkdir /var/lib/lightdm-cinema-greeter
	chown lightdm.lightdm /var/lib/lightdm-cinema-greeter
	cp share/* /usr/share/lightdm-cinema-greeter
	chown root.lightdm /usr/share/lightdm-cinema-greeter/*
	cp data/lightdm-cinema-greeter.desktop /usr/share/xgreeters
	ln -sfn /usr/share/xgreeters/lightdm-cinema-greeter.desktop /etc/alternatives/lightdm-greeter
	cp data/lightdm-cinema-greeter.mo /usr/share/locale/de/LC_MESSAGES



