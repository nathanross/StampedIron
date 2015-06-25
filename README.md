#StampedIron

Stamped Iron is a short, readable, and fully-functional proof-of-concept of a server imaging approach that addresses an imaging workflow gap.

It demonstrates that bootstrapping a server image script:

- **doesn't require trust in the security of a complex third party tool, nor its distro templates**  
- **makes use of an existing vanilla debian iso.**
- doesn't abstract away the ISO intermediary step, so you can automate booted installation on bare metal.
- is simple enough to read and understand in entirety in a few hours
- requires no familiarity with a specific scripting language beyond bash.  

There are many testability and security benefits to all your server instances starting on the same, trusted, foundation. When Debian issues security updates, they issue them in response to vulnerabilities and conditions within the vanilla OS packaging and configuration.

An increasing diversity of imaging and tools require or expect the provisioning of custom spins or treatments of distros that are seemingly universally configured and packaged using undocumented differences from the vanilla install.

But loss of security does not have to be a cost of automation: gaining that security back begins, if not with using standard packaging and config or being able to compare 1:1 against it.

The idea of this tool isn't to solve any problems in any new, or even particularly interesting way. Rather in the most predictable way, such that sysadmins (who need to keep in mind endemic major chain-of-trust problems inherent in many container and VM build automation tools) resigned to rolling their own script bootstrap, can basically look at these scripts and, without having to dig through unrelated complexity, see many exact same steps he would have taken, and either use it as a guide or as it is.

##stampedIron.sh :

a convenience script for creating vm instances. Runs the below scripts in series using the provided input sources (seedfiles, recipe dirs), caching the results of the first (autoinstall iso) and second (installed disk image) for easy testing of recipe chanegs.

##tools/inject_seedfile:

injecting a debian seedfile (and optionally, a directory) into a debian-based iso and rebuilding into an iso.

##tools/install_autoinstall_iso:

create a disk of custom size, and using a provided iso booting a VM with reasonable HW defaults, with the created disk as /dev/sda.

##tools/run_image:

using a provided disk boot a VM with reasonable HW defaults, optionally creating an image from a provided directory added as a 2nd drive on the filesystem.

If the ISO is created by inject_seedfile, an automation_shim is inserted into the seedfile. When run_image is provided with a directory to provide as a device, this automation shim will mount it at /mnt at boot. As well, if a script entitled 'run.sh' (bash or /bin/sh are both fine) exists within the root of the directory, it is run at that time.

Because I don't want to preclude composing an image out of multiple bash recipes, this automation_shim will not self-delete after first run. Instead, after you have no need of it, it is best to remove it. This can be done two ways:

1. (From outside the VM) ```./run_image.sh <disk image>::1 ./automation_shim/rm_shim::2```
2. (From within the VM, as root) ```rm /etc/systemd/system/auto_shim.service /etc/systemd/system/multi-user.target.wants/auto_shim.service```

## related tools

There are some tools that do similar work.

- virtinst has different goals than this tool, and actually works complemantarily (it replaces the install.sh and run_image.sh fn.). The main function of this tool is to create an imaging install iso, so getting the same image on bare metal dosen't require opening up each and every computer to swap out the hard drive out or attach a cable to it from another computer while it does the install process. For VMs, though, virt-install can be used on the autoinstall iso, or to simply inject the seedfile and automation shim in this repo on top of the vanilla distro.
- Simple-cdd is a nice tool, but focuses on debian alone, uses a non-default set of packages and configuration, and prioritize user interface over absolute simplicity.


## setup example squid VM


```
apt-get -y install virsh qemu-kvm
mkdir /var/cache/install_discs
wget -c http://cdimage.debian.org/debian-cd/8.1.0/amd64/iso-cd/debian-8.1.0-amd64-CD-1.iso -P /var/cache/install_discs
virsh net-create virsh/network.xml
( source examples/squid_image.sh ; ./stampedIron )
squid_ip=`WAIT_FOR_IP=1 ./tools/./run_image.sh /srv/squid/output.disk | cut -d, -f2`
export PROXY_SOCKET=$squid_ip:3128

#example, use the proxy with wget
echo "HTTP_PROXY=$PROXY" >> ~/.wgetrc
example_file=http://archive.org/download/ItsAllOverNowBabyBlue_201506/It%27s%20all%20over%20now%20baby%20blue.mp3
wget $example_file
wget $example_file

```

## Using VM imaging tools to solve the BTRFS UUID problem.

a typical contractual requirement in supplying VM images to another company is that all UUID
images be different. With EXT family and many other FS, to an extent this could (if not
installing a plethora of unfamiliar packages) be effectively 'faked' by tuning the fs
and replacing known locations for references to it (e.g. regenerating initrd image)

However, it is exceedingly difficult to implement this on a *generalized* level with BTRFS, as there is no *complete* cloning tool for a BTRFS filesystem to another filesystem with a different UUID - perfectly replicating a BTRFS filesystem (different snapshots, attributes and all) barring a different UUID requires creating a specific migration script with knowledge of the original filesystem. Solving for this for arbitrary BTRFS filesystems can only be currently done by recreating the exact steps that were used to create the original.

This is exactly what StampedIron does through seedfile injection, unattended install, and bash script shim, allowing creation of arbitrary functionally identical BTRFS filesystems save for UUID, making contractual obligations in regard to delivery of BTRFS-backed server images much faster.

example

```
(envsubst '$PROXY' < examples/seedfiles/debian.btrfs_raid1.mirrored.seed) > /tmp/preseed
for id in 1 2 3; do
    ( source example/apache_image.sh ; SEEDFILE=/tmp/preseed; OUTDIR=/srv/apache$id; ./stampedIron )
done

```
