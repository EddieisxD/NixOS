{
  size = "2G";
  type = "EF00"; # GPT partition type code for EFI System
  content = {
    type = "filesystem";
    format = "vfat";
    mountpoint = "/boot";
    mountOptions = [ "umask=0077" ];
  };
}
