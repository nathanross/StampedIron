#Vm_construction

The goal of StampedIron's VM Construction toolset is to make security conscious VM AND bare-metal-install Build Automation easy.:

 * A hands-off open-source autoinstall ISO creation, VM disk image creation, distro install and recipe bootstrapping pipeline
 * that doesn't require your trust in the security of a complex third party tool or its distro templates
 * that makes use of an existing vanilla debian, ubuntu server, or RHEL iso.
 * is simple enough to read and understand in entirety in half of a workday.

  There are many testability and security benefits to all your server instances starting on the same, trusted, foundation. Third-party binaries are subject to repository integrity attacks, security oversights, and human error. In addition, third party distro templates (including lxc) are seemingly universally configured and packaged in undocumented ways different than that in a vanilla distro install. 

  There are some tools that do similar work. Simple-cdd is a nice tool, but focuses on debian alone, uses a non-default set of packages and configuration, and prioritize user interface over absolute simplicity.

  The idea of this tool isn't to solve any problems in any new, or particularly interesting way. Rather in the most predictable way such that a sysadmin is concerned about the major chain-of-trust problems inherent in container and VM build automation tools, and resigns to rolling their own, can basically look at these scripts and, without having to dig through unrelated complexity, see many exact same steps he would have taken, and either use it as a guide or as it is.

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

## Package caching

  in the examples/squid directory is an image you can use to create a package cache. 
  
  