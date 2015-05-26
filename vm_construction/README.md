#Vm_construction

this directory contains tools for:

##inject_seedfile:

injecting a debian seedfile (and optionally, a directory) into a debian-based iso and rebuilding into an iso.

##install_autoinstall_iso:

create a disk of custom size, and using a provided iso booting a VM with reasonable HW defaults, with the created disk as /dev/sda.

##run_image:

using a provided disk boot a VM with reasonable HW defaults, optionally creating an image from a provided directory added as a 2nd drive on the filesystem.

If the ISO is created by inject_seedfile, an automation_shim is inserted into the seedfile. When run_image is provided with a directory to provide as a device, this automation shim will mount it at /mnt at boot. As well, if a script entitled 'run.sh' (bash or /bin/sh are both fine) exists within the root of the directory, it is run at that time.

Because I don't want to preclude composing an image out of multiple bash recipes, this automation_shim will not self-delete after first run. Instead, after you have no need of it, it is best to remove it. This can be done two ways:

1. (From outside the VM) ./run_image.sh <disk image> ./automation_shim/rm_shim

2. (From within the VM, as root) rm /etc/systemd/system/auto_shim.service /etc/systemd/system/multi-user.target.wants/auto_shim.service

