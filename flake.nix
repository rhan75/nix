{
  description = "Universal configuration for Mac and Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, ... }:
  let
    username = "ryanhan";

    commonPackages = pkgs: with pkgs; [
      neovim git tmux jq fzf htop
      coreutils gh wget tree micromamba obsidian alacritty flutter jdk
      docker discord slack vscode ghidra nmap
      azure-cli tailscale google-chrome powershell
    ];
    commonFonts = pkgs: with pkgs; [
      noto-fonts-cjk
      noto-fonts-emoji
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      jetbrains-mono
    ];
    darwinPackages = pkgs: with pkgs; [

    ];

    linuxPackages = pkgs: with pkgs; [
      code-cursor vmware-workstation _1password-gui _1password figma-linux
    ];

    darwinConfiguration = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = commonPackages pkgs ++ darwinPackages pkgs;
      fonts.packages = commonFonts pkgs;
      
      system.stateVersion = 5;
      # Add this line to enable the Nix daemon
      services.nix-daemon.enable = true;
      homebrew = {
        enable = true;
        casks = [
          "cursor" "anaconda" "iterm2" "notion"
          "font-hack-nerd-font" "font-fira-code-nerd-font"
          "figma" "microsoft-teams" "rectangle-pro"
          "signal" "vmware-fusion" "dotnet-sdk"
          "1password" "1password-cli"
        ];
        onActivation.cleanup = "zap";
      };
      
      # ... other Darwin-specific configurations ...
    };

    linuxConfiguration = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = commonPackages pkgs ++ linuxPackages pkgs;
      fonts.packages = commonFonts pkgs;
      services.flatpak.enable = true;
      # Add Notion as a Flatpak package
      # services.flatpak.packages = [
        # "flathub:app/md.obsidian.Obsidian"
      # ];

      # ... other Linux-specific configurations ...
    };

  in
  {
    darwinConfigurations."macos" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";  # Adjust if needed
      modules = [ 
        darwinConfiguration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = username;
            enableRosetta = true;
            autoMigrate = true;
          };
        }
        # home-manager.darwinModules.home-manager
        # {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #   home-manager.users.${username} = { ... }: {
        #     # Add your home-manager configuration here
        #   };
        # }
      ];
    };

    nixosConfigurations."linux" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";  # Adjust this to your Linux system architecture
      modules = [
        linuxConfiguration
        # home-manager.nixosModules.home-manager
        # {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #   home-manager.users.${username} = { ... }: {
        #     # Add your home-manager configuration here
        #   };
        # }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."macos".pkgs;
  };
}