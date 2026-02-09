{ config, lib, pkgs, ... }: {

  
  hardware.nvidia-container-toolkit.enable = true;
  hardware.intel-gpu-tools.enable = true;

  boot.blacklistedKernelModules = [ "nouveau" ];

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Required for modern Intel GPUs (Xe iGPU and ARC)
      intel-media-driver     # VA-API (iHD) userspace
      vpl-gpu-rt             # oneVPL (QSV) runtime
      # Optional (compute / tooling):
      intel-compute-runtime  # OpenCL (NEO) + Level Zero for Arc/Xe
      libva-utils
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";     # Prefer the modern iHD backend
    # VDPAU_DRIVER = "va_gl";      # Only if using libvdpau-va-gl
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia" "modesetting"]; # include "modesetting" in case you are running x11

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    
    forceFullCompositionPipeline = false;
    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {

      sync.enable = false;

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      reverseSync.enable = false;

      # Make sure to use the correct Bus ID values for your system!
      # Address Format: A full PCI address is written as domain@bus:device:function
      # Domain denotes the CPU number ... it stats from 0 then what bus of the CPU then which device and which function is being called
      intelBusId  = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:0@1:0:0";
      # amdgpuBusId = "PCI:54:0:0"; For AMD GPU
    };
    

  };
}
