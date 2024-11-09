{
  description = "Zenful Darwin Nix Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let

 #   system = "aarch64-darwin";

    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
	  pkgs.neovim
    pkgs.git
	  pkgs.obsidian
	  pkgs.tmux
	  pkgs.jq
	  pkgs.fzf
	  pkgs.htop
	  pkgs.coreutils
	  pkgs.gh
	  pkgs.wget
	  pkgs.tree
	  pkgs.micromamba
	  pkgs.docker
	  pkgs.ghidra
	  pkgs.nmap
	  pkgs.tailscale
        ];


      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        casks = [
          "cursor"
          "google-chrome"
          "notion"
          "1password"
	        "1password-cli"
	        "microsoft-teams"
	        "rectangle-pro"
	        "microsoft-outlook"
	        "figma"
	        "vmware-fusion"
	        "font-meslo-lg-nerd-font"
          "iterm2"
          "tailscale"
          "nordvpn"
        ];
        masApps = {
          # "Yoink" = 457622435;
        };
        onActivation.cleanup = "zap";
      };

      fonts.packages = 
        [
	  pkgs.fira-code
          #pkgs.hack-font
          #pkgs.source-code-pro
          #pkgs.jetbrains-mono
	];
      system.activationScripts.applications.text = let
  	env = pkgs.buildEnv {
	  name = "system-applications";
	  paths = config.environment.systemPackages;
	  pathsToLink = "/Applications";
  	};
      in
  	pkgs.lib.mkForce ''
  	  # Set up applications.
  	  echo "setting up /Applications..." >&2
  	  rm -rf /Applications/Nix\ Apps
  	  mkdir -p /Applications/Nix\ Apps
  	  find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
  	  while read src; do
    	    app_name=$(basename "$src")
    	    echo "copying $src" >&2
    	    ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
  	  done
        '';

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            # Apple Silicon Only
            enableRosetta = true;
            # User owning the Homebrew prefix
            user = "biogi";

            autoMigrate = true;
          };
        }
      ];
    };


    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mini".pkgs;
  };
}
