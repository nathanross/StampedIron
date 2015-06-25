# IMPORTANT

The files in this directory are M4 files, you cannot
run them directly as preseed files, but you can generate
a vanilla preseed files from them by running, for example:

```m4 debian.seed.m4 > debian.seed```

These will produce healthy defaults for a seedfile. If you
don't want to use M4, you can just edit this generated file.

However, as an example of what M4 macros, each seedfile has
a macro allowing you to specify the socket addr for a package
downloading proxy.

```m4 -D SOCKET_ADDR=192.168.10.8:3128 debian.seed.m4 > debian.seed```

The other macro in these files is meant to show the complexity
of partitioning available in seedfiles. E.g. passing BTRFS_RAID1=true
will mean that instead of having a single ext4 partition, the partition
scheme is two partitions formatted as BTRFS RAID1 and an ext4 boot partition.

These M4 files are not intended to be an end-all be-all preseed
for all applications. Not at all. They're just provided
as an example of how useful M4 is for configuring provision-sensitive values
in a preseed.

A good practice is to create an M4 file containing all of the configuration
items which will be relatively static, and parameterizing only the few
that you will change often. Generally, the less that is configured at base filesystem
creation time (and the more configured at imaging time via bash scripts, puppet, etc.),
the better.

So for example if you wanted to on some images use the 'standard' metapackage and on
others not, a good approach would be to just not include it by default in the filesystem
and then install it where appropriate during imaging.