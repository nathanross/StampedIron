#!/bin/bash

# Copyright 2015 Nathan Ross
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# IMPORTANT IF A DEBIAN PRESEED FILE HAS A COMMENT
# ON THE SAME LINE AS A DIRECTIVE, THAT DIRECTIVE
# WILL CAUSE AN ERROR OR BE IGNORED

# Example of using M4 to parameterize preseed

# GENERATE A PRESEED WHICH USES BTRFS_RAID1,
# RUN m4 -D BTRFS_RAID1=1 debi...

# TO GENERATE A PRESEED 


# -- language, keymap ------------------------------
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us
d-i console-keymaps-at/keymap select us
d-i console-setup/layoutcode string us
d-i console-setup/variantcode string dvorak
d-i pkgsel/language-packs multiselect en

# -- time ------------------------------------------
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true

# -- LAN, sources -----------------------------------
d-i netcfg/choose_interface select eth0
d-i netcfg/get_hostname string pc
d-i netcfg/get_domain string loc.al
#d-i mirror/http/mirror select http.us.debian.org
d-i mirror/country string us
d-i mirror/http/hostname string ftp.us.debian.org
d-i mirror/http/directory string /debian
#d-i mirror/suite string testing

ifdef(`PROXY_SOCKET', `
d-i mirror/http/proxy string http://PROXY_SOCKET
d-i apt-setup/use_mirror boolean true
', `
#d-i mirror/http/proxy string http://PROXY_SOCKET
d-i apt-setup/use_mirror boolean false
')


# -- accounts ------------------------------------
#both root password directives necessary for debian only.
#but result is that in both root account has password a
d-i passwd/root-password password a
d-i passwd/root-password-again password a
d-i passwd/user-fullname string ace
d-i passwd/username string ace
d-i passwd/user-password password ace
d-i passwd/user-password-again password ace
d-i passwd/make-user boolean false
#todo
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false

# -- partman (boilerplate) ------------------------
d-i partman-md/confirm boolean true
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition \
       select Finish partitioning and write changes to disk	
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/mount_style select label
d-i partman-basicfilesystems/no_swap boolean false


# -- opt. packages or package groups -------------
# it's suggested that you use 'standard' here
# 'desktop' is generally what you add if you want that.
# but 'none' is always an option.
# you can see the packages entailed in standard via
# 'aptitude search ~pstandard ~prequired ~pimportant -F%p'
tasksel tasksel/first multiselect none
# set to select none if you don't want unattended.
d-i pkgsel/update-policy select none
#update apt packages db, set to false if no network
d-i pkgsel/updatedb boolean true
#set to none if no network.
#full-upgrade for full-upgrade
d-i pkgsel/upgrade select none


# -- apt and sources list -----------------------
#don't ask for next cd.
d-i apt-setup/main boolean true
d-i apt-setup/contrib boolean true
d-i apt-setup/services-select multiselect security, updates
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/cdrom/set-next boolean false
d-i apt-setup/cdrom/set-failed boolean false
popularity-contest popularity-contest/participate boolean false

#    in-target systemctl enable auto_shim.service;

# -- partitioning ---------------------------------
d-i partman-auto/method string regular

define(TOTAL_S, ifdef(`TOTAL_SIZE', `TOTAL_SIZE', 14500))
define(USABLE_S, eval(TOTAL_S `-1000'))
define(USABLE_SP, eval(USABLE_S ` + 1'))
define(HALF_USABLE_S, eval(USABLE_S ` / 2'))
define(HALF_USABLE_SP, eval(HALF_USABLE_S ` + 1'))


# the percentage priority system works in a way
# not exactly as you might expect - two equal
# prio partitions mean only one will expand.
# expect to use manual config for now.
#d-i partman-auto/expert_recipe string \
#      extgpt :: \
#              512 512 512 fat16         \
#                $primary{ }             \
#                $iflabel{ gpt }         \
#                method{ efi }           \
#                label { boot }          \
#                format{ }               . \
#              USABLE_S 50 USABLE_SP ext4 \
#                $primary{ } \
#                $bootable{ } \
#                method{ format } format{ } \
#                use_filesystem{ } \
#                filesystem{ ext4 } \
#                mountpoint{ / } \
#                options/noatime{ noatime } . \
#              500 100 2000 linux-swap \
#                $primary{ } \
#                method{ swap } format{ } .


#d-i partman-auto/expert_recipe string \
#      btrfsgpt :: \
#              512 512 512 fat16         \
#                $primary{ }             \
#                $iflabel{ gpt }         \
#                method{ efi }           \
#                label { boot }          \
#                format{ }               . \
#              HALF_USABLE_S 50 HALF_USABLE_SP btrfs        \
#                method{ format } format{ } \
#                use_filesystem{ }        \
#                filesystem{ btrfs }      \
#                mountpoint{ / }          \
#                label { usb_raid }       \
#                options/noatime{ noatime } . \
#              HALF_USABLE_S 50 HALF_USABLE_SP btrfs         \
#                method{ }                \
#                filesystem{ btrfs } \
#                options/noatime{ noatime } . \
#              100 5 -1 ext4                \
#                $bootable{ }             \
#                method{ }                \
#                filesystem{ ext4 }       \
#                options/noatime{ noatime } .

#GPT install - the below lines should be uncommented if you want a GPT
#install, and commented out if you want MBR
#d-i   grub-installer/bootdev string /dev/sda1
#d-i   partman-basicfilesystems/choose_label string gpt
#d-i   partman-basicfilesystems/default_label string gpt
#d-i   partman-partitioning/choose_label string gpt
#d-i   partman-partitioning/default_label string gpt
#d-i   partman/choose_label string gpt
#d-i   partman/default_label string gpt
#partman-partitioning  partman-partitioning/choose_label select gpt

#MBR install - the below lines should be uncommented if you want an MBR
#install, and commented out if you want GPT
d-i   grub-installer/bootdev string /dev/sda
ifelse(BTRFS_RAID1, `true', `
d-i partman-auto/expert_recipe string \
      btrfsmbr :: \
              HALF_USABLE_S 50 HALF_USABLE_SP btrfs \
                $primary{ } \
                $bootable{ } \
                method{ format } format{ } \
                use_filesystem{ } \
                filesystem{ btrfs } \
                mountpoint{ / } \
                options/ssd{ ssd } \
                options/noatime{ noatime } . \
              HALF_USABLE_S 50 HALF_USABLE_SP btrfs \
                $primary{ } \
                $bootable{ } \
                method{ } \
                filesystem{ btrfs } \
                options/noatime{ noatime } . \
            100 5 -1 ext4 \
                $primary{ }  \
                $bootable{ } \
                method{ format } format{ } \
                use_filesystem{ } \
                filesystem{ ext4 } \
                mountpoint{ /boot } \
                options/noatime{ noatime } .
d-i preseed/late_command string \
    in-target btrfs device add -f /dev/sda2 /; \
    in-target btrfs balance start -dconvert=raid1 -mconvert=raid1 /;
', `
d-i partman-auto/expert_recipe string \
      extmbr :: \
              USABLE_S 50 USABLE_SP ext4 \
                $primary{ } \
                $bootable{ } \
                method{ format } format{ } \
                use_filesystem{ } \
                filesystem{ ext4 } \
                mountpoint{ / } \
                options/noatime{ noatime } . \
              500 100 2000 linux-swap \
                $primary{ } \
                method{ swap } format{ } .
'
)
# -- grub and reboot ----------------------------
d-i grub-installer/only_debian boolean true
d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/poweroff boolean true
