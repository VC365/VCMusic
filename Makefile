.PHONY: all install uninstall build mo desktop
PREFIX ?= /usr
PO_LOCATION ?= po
LOCALE_LOCATION ?= /share/locale
msys_sys ?= mingw64

all: desktop build

build:
	VCMUSIC_LOCALE_LOCATION="$(PREFIX)$(LOCALE_LOCATION)" $(CRYSTAL_LOCATION)shards build --release -p

clean:
	rm -rf po/mo
	rm -f  data/ir.NonFree.VCMusic.metainfo.xml
	rm -f  data/ir.NonFree.VCMusic.desktop
run:
	VCMUSIC_LOCALE_LOCATION="$(PREFIX)$(LOCALE_LOCATION)" $(CRYSTAL_LOCATION)shards run -p

mo:
	mkdir -p $(PO_LOCATION)/mo
	for lang in `cat "$(PO_LOCATION)/LINGUAS"`; do \
	    if [ "$$lang" = "en" ] || [ -z "$$lang" ]; then continue; fi; \
	    mkdir -p "$(PREFIX)$(LOCALE_LOCATION)/$$lang/LC_MESSAGES"; \
	    msgfmt "$(PO_LOCATION)/$$lang.po" -o "$(PO_LOCATION)/mo/$$lang.mo"; \
		install -D -m 0644 "$(PO_LOCATION)/mo/$$lang.mo" "$(PREFIX)$(LOCALE_LOCATION)/$$lang/LC_MESSAGES/ir.NonFree.VCMusic.mo"; \
	done

metainfo:
	msgfmt --xml --template data/ir.NonFree.VCMusic.metainfo.xml.in -d "$(PO_LOCATION)" -o data/ir.NonFree.VCMusic.metainfo.xml

desktop:
	msgfmt --desktop --template data/ir.NonFree.VCMusic.desktop.in -d "$(PO_LOCATION)" -o data/ir.NonFree.VCMusic.desktop

install: mo metainfo desktop
	install -D -m 0755 bin/VCMusic $(PREFIX)/bin/VCMusic
	install -D -m 0644 data/ir.NonFree.VCMusic.desktop $(PREFIX)/share/applications/ir.NonFree.VCMusic.desktop
	install -D -m 0644 data/icons/hicolor/scalable/apps/ir.NonFree.VCMusic.svg $(PREFIX)/share/icons/hicolor/scalable/apps/ir.NonFree.VCMusic.svg
	install -D -m 0644 data/icons/hicolor/symbolic/ir.NonFree.VCMusic-symbolic.svg $(PREFIX)/share/icons/hicolor/symbolic/apps/ir.NonFree.VCMusic-symbolic.svg
	gtk-update-icon-cache $(PREFIX)/share/icons/hicolor

uninstall:
	rm -f $(PREFIX)/bin/VCMusic
	rm -f $(PREFIX)/share/applications/ir.NonFree.VCMusic.desktop
	rm -f $(PREFIX)/share/icons/hicolor/scalable/apps/ir.NonFree.VCMusic.svg
	rm -f $(PREFIX)/share/icons/hicolor/symbolic/apps/ir.NonFree.VCMusic-symbolic.svg
	rm -rf $(PREFIX)$(LOCALE_LOCATION)/*/*/ir.NonFree.VCMusic.mo
	gtk-update-icon-cache $(PREFIX)/share/icons/hicolor

validate-appstream:
	appstreamcli validate ./data/ir.NonFree.VCMusic.metainfo.xml.in

windows:
	rm -rf "VCMusic_win"
	mkdir -p "VCMusic_win/bin"
	mkdir -p "VCMusic_win/share/applications"
	mkdir -p "VCMusic_win/share/icons"
	mkdir -p "VCMusic_win/share/locale"

	VCMUSIC_LOCALE_LOCATION=".$(LOCALE_LOCATION)" $(CRYSTAL_LOCATION)shards build --release -p
	mv ./bin/VCMusic.exe ./VCMusic_win/bin/

	wget -nc https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe
	rsvg-convert ./data/icons/hicolor/scalable/apps/ir.NonFree.VCMusic.svg -o ./data/icons/ir.NonFree.VCMusic.png -h 256 -w 256
	magick -density "256x256" -background transparent ./data/icons/ir.NonFree.VCMusic.png -define icon:auto-resize -colors 256 ./data/icons/ir.NonFree.VCMusic.ico
	./rcedit-x64.exe ./VCMusic_win/bin/VCMusic.exe --set-icon ./data/icons/ir.NonFree.VCMusic.ico

	ldd ./VCMusic_win/bin/VCMusic.exe | grep '\/$(msys_sys).*\.dll' -o | xargs -I{} cp "{}" ./VCMusic_win/bin
	cp -f /$(msys_sys)/bin/gdbus.exe ./VCMusic_win/bin && ldd ./VCMusic_win/bin/gdbus.exe | grep '\/$(msys_sys).*\.dll' -o | xargs -I{} cp "{}" ./VCMusic_win/bin
	cp -f /$(msys_sys)/bin/gspawn-win64-helper.exe ./VCMusic_win/bin && ldd ./VCMusic_win/bin/gspawn-win64-helper.exe | grep '\/$(msys_sys).*\.dll' -o | xargs -I{} cp "{}" ./VCMusic_win/bin
	cp -f /$(msys_sys)/bin/librsvg-2-2.dll /$(msys_sys)/bin/libgthread-2.0-0.dll /$(msys_sys)/bin/libgmp-10.dll ./VCMusic_win/bin
	cp -r /$(msys_sys)/lib/gio/ ./VCMusic_win/lib
	cp -r /$(msys_sys)/lib/gdk-pixbuf-2.0 ./VCMusic_win/lib/gdk-pixbuf-2.0

	ldd ./VCMusic_win/lib/gio/*/*.dll | grep '\/$(msys_sys).*\.dll' -o | xargs -I{} cp "{}" ./VCMusic_win/bin
	ldd ./VCMusic_win/bin/*.dll | grep '\/$(msys_sys).*\.dll' -o | xargs -I{} cp "{}" ./VCMusic_win/bin
	ldd ./VCMusic_win/lib/gdk-pixbuf-2.0/*/loaders/*.dll | grep '\/$(msys_sys).*\.dll' -o | xargs -I{} cp "{}" ./VCMusic_win/bin

	mkdir -p $(PO_LOCATION)/mo
	for lang in `cat "$(PO_LOCATION)/LINGUAS"`; do \
		if [[ "$$lang" == 'en' || "$$lang" == '' ]]; then continue; fi; \
		mkdir -p "./VCMusic_win$(LOCALE_LOCATION)/$$lang/LC_MESSAGES"; \
		msgfmt "$(PO_LOCATION)/$$lang.po" -o "$(PO_LOCATION)/mo/$$lang.mo"; \
		install -D -m 0644 "$(PO_LOCATION)/mo/$$lang.mo" "./VCMusic_win$(LOCALE_LOCATION)/$$lang/LC_MESSAGES/ir.NonFree.VCMusic.mo"; \
	done
	msgfmt --desktop --template data/ir.NonFree.VCMusic.desktop.in -d "$(PO_LOCATION)" -o ./VCMusic_win/share/applications/ir.NonFree.VCMusic.desktop

	cp -r /$(msys_sys)/share/icons/ ./VCMusic_win/share/

	rm -rf ./VCMusic_win/share/icons/hicolor/scalable/actions/
	find ./VCMusic_win/share/icons/ -name *.*.*.svg -not -name *NonFree* -delete
	find ./VCMusic_win/lib/gdk-pixbuf-2.0/2.10.0/loaders -name *.a -not -name *NonFree* -delete
	find ./VCMusic_win/share/icons/ -name mimetypes -type d  -exec rm -r {} + -depth
	find ./VCMusic_win/share/icons/hicolor/ -path */apps/*.png -not -name *NonFree* -delete
	find ./VCMusic_win/ -type d -empty -delete
	gtk-update-icon-cache ./VCMusic_win/share/icons/Adwaita/
	gtk-update-icon-cache ./VCMusic_win/share/icons/hicolor/

	zip -r9q VCMusic_win.zip VCMusic_win/