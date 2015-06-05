#StampedIron

Stamped Iron is a short, readable, and fully-functional proof-of-concept of a server imaging approach that addresses an imaging workflow gap.

It demonstrates that bootstrapping a server image script:

- **doesn't require trust in the security of a complex third party tool or its distro templates**  
- **makes use of an existing vanilla debian, ubuntu server, or RHEL iso.**
- doesn't abstract away the ISO intermediary step, so you can automate booted installation on bare metal.
- is simple enough to read and understand in entirety in a few hours
- requires no familiarity with a specific scripting language beyond bash.  

There are many testability and security benefits to all your server instances starting on the same, trusted, foundation. When Debian and RHEL issue security updates, they issue them in response to vulnerabilities and conditions within the vanilla OS packaging and configuration.

An increasing diversity of imaging and tools require or expect the provisioning of custom spins or treatments of distros that are seemingly universally configured and packaged using undocumented differences from the vanilla install.

But loss of security does not have to be a cost of automation: gaining that security back begins, if not with using standard packaging and config or being able to compare 1:1 against it.

The idea of this tool isn't to solve any problems in any new, or even particularly interesting way. Rather in the most predictable way, such that sysadmins (who need to keep in mind endemic major chain-of-trust problems inherent in many container and VM build automation tools) resigned to rolling their own script bootstrap, can basically look at these scripts and, without having to dig through unrelated complexity, see many exact same steps he would have taken, and either use it as a guide or as it is.

##inject_seedfile:

injecting a debian seedfile (and optionally, a directory) into a debian-based iso and rebuilding into an iso.

##install_autoinstall_iso:

create a disk of custom size, and using a provided iso booting a VM with reasonable HW defaults, with the created disk as /dev/sda.

##run_image:

using a provided disk boot a VM with reasonable HW defaults, optionally creating an image from a provided directory added as a 2nd drive on the filesystem.

If the ISO is created by inject_seedfile, an automation_shim is inserted into the seedfile. When run_image is provided with a directory to provide as a device, this automation shim will mount it at /mnt at boot. As well, if a script entitled 'run.sh' (bash or /bin/sh are both fine) exists within the root of the directory, it is run at that time.

Because I don't want to preclude composing an image out of multiple bash recipes, this automation_shim will not self-delete after first run. Instead, after you have no need of it, it is best to remove it. This can be done two ways:

1. (From outside the VM) ```./run_image.sh <disk image>:1 ./automation_shim/rm_shim:2```
2. (From within the VM, as root) ```rm /etc/systemd/system/auto_shim.service /etc/systemd/system/multi-user.target.wants/auto_shim.service```

## related tools

There are some tools that do similar work.
- virtinst has the same capabilities with some tooling, but has several hundred mb of additional dependencies (incl. x11) and abstracts away the ISO intermediary step. Which means getting an image on bare metal means opening up each and every computer to swap out the hard drive out or attach a cable to it from another computer while it does the install process.
- Simple-cdd is a nice tool, but focuses on debian alone, uses a non-default set of packages and configuration, and prioritize user interface over absolute simplicity.
