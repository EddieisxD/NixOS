
# Goal

The goal is to reduce the time it takes for my nixos configuration to compile.

# Tools and Statergies

- nix (determinant systems); extra-experimental-features = parallel-eval
- lix (doesn't support parallel eval yet but is planned)
- extra-sandbox-paths = /var/cache/ccache; ccache (compiler cache) helps speed up the process for derivation builds
- nix-fast-build (lix's official recommendation)
- colmena (multi machine builds)
- nix-eval-jobs / hydra-eval-jobs (recommendation by lix)
- nix-ninja (reduces the redundancy during compilation of packages)
- documentation.nixos.enable = false; reduces the single thread work during evaluation
- Enable the Evaluation Cache:.cache/nix/eval-cache-vX
- attn or Custom Shell Parallelism
- mold (faster linker)
- avoid IFD (import from derivation)
- remove git history being copied in the nix/store

# Implementations and cons:

- Implementing the safest thing first `documentation.nixos.enable = false;` the cons for this is This stops you from using nixos-help locally.
- removing the git history being copied inside /nix/store/; cons none, this increase the speed and reduce the disk size.
