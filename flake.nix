{
  description = "Personal dotfiles with Homebrew + mise + Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS専用（必要な場合）
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # 使用しているシステムを指定
      system = "aarch64-darwin";  # Apple Silicon

      pkgs = nixpkgs.legacyPackages.${system};

      username = "r0227n";
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [ ./home.nix ];

        extraSpecialArgs = {
          inherit inputs system username;
        };
      };
    };
}
