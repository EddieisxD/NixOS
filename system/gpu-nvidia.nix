{ config, lib, pkgs, ... }: {

  
  hardware.nvidia-container-toolkit.enable = true;
  hardware.intel-gpu-tools.enable = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Required for modern Intel GPUs (Xe iGPU and ARC)
      intel-media-driver     # VA-API (iHD) userspace
      vpl-gpu-rt             # oneVPL (QSV) runtime
      intel-compute-runtime  # OpenCL (NEO) + Level Zero for Arc/Xe
      libva-utils
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";     # Prefer the modern iHD backend
    # VDPAU_DRIVER = "va_gl";      # Only if using libvdpau-va-gl
  };

  # Load nvidia driver for Xorg and Wayland
  # Display is on Intel iGPU (modesetting), NVIDIA is only for PRIME offload
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;
    
    # forceFullCompositionPipeline = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaPersistenced = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;
    prime = {
      sync.enable = false;
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      reverseSync.enable = false;
      intelBusId  = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:0@1:0:0";
      # amdgpuBusId = "PCI:54:0:0"; For AMD GPU

    };
  };

  specialisation."no-gpu".configuration = {
    system.nixos.tags = [ "no-gpu" ];

    # 1. Use ONLY Intel iGPU
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];

    # 2. Blacklist NVIDIA from the kernel
    boot.blacklistedKernelModules = lib.mkForce [
      "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" 
      "nvidia_uvm" "nvidia_fb" "i2c_nvidia_gpu"
    ];

    # 3. Fixed Stage 1 Modules (Disk + Crypto)
    boot.initrd.availableKernelModules = lib.mkForce [ 
      "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vmd" "crc32c" "intel_lpss_pci" 
    ];

    # 4. Disable NVIDIA-specific tools
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;

    # 5. Logical PCI Removal (The heat-stopper)
    services.udev.extraRules = ''
      # Remove NVIDIA Graphics & Audio
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{remove}="1"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
    '';
  };
}
