# Tiny File Manager by prasathmani <https://tinyfilemanager.github.io>
# Copyright (C) 2022 muink <https://github.com/muink>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-tinyfilemanager
PKG_VERSION:=2.5.0-20221126
#PKG_RELEASE:=1

LUCI_TITLE:=LuCI Tiny File Manager
LUCI_DEPENDS:=+php8 +php8-cgi +php8-mod-session +php8-mod-ctype +php8-mod-fileinfo +php8-mod-zip +php8-mod-iconv +php8-mod-mbstring +coreutils-stat +zoneinfo-asia +bash +curl +tar

LUCI_DESCRIPTION:=A Web based File Manager in PHP

define Package/$(LUCI_NAME)/conffiles
/etc/config/tinyfilemanager
endef

define Package/$(LUCI_NAME)/postinst
#!/bin/sh
mkdir -p /www/tinyfilemanager 2>/dev/null
[ ! -d /www/tinyfilemanager/rootfs ] && ln -s / /www/tinyfilemanager/rootfs
total_size_limit=5G        #post_max_size = 8M
single_size_limit=2G       #upload_max_filesize = 2M
otime_uploads_limit=200    #max_file_uploads = 20
sed -Ei "s|^(post_max_size) *=.*$$|\1 = $$total_size_limit|; \
         s|^(upload_max_filesize) *=.*$$|\1 = $$single_size_limit|; \
         s|^(max_file_uploads) *=.*$$|\1 = $$otime_uploads_limit|" \
/etc/php.ini
# unpack
tar -o -C '/www/tinyfilemanager' -xzvf '/www/tinyfilemanager/index.tgz'
rm -f '/www/tinyfilemanager/index.tgz'
# start service
/etc/init.d/tinyfilemanager start
endef

define Package/$(LUCI_NAME)/prerm
#!/bin/sh
if [ -d /www/tinyfilemanager ]; then rm -rf /www/tinyfilemanager; fi
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
