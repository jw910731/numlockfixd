{
  description = "numlockfixd";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable"; };

  outputs = { self, nixpkgs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ];
    in {
      packages = forEachSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          xcode = pkgs.xcodeenv.composeXcodeWrapper { };
          xcodeHook = pkgs.makeSetupHook {
            name = "xcode-hook";
            propagatedBuildInputs = [ xcode ];
          } "${pkgs.xcbuildHook}/nix-support/setup-hook";
        in {
          numlockfixd = pkgs.stdenvNoCC.mkDerivation {
            pname = "numlockfixd";
            version = "v0.0.1";
            src = with pkgs.lib.fileset;
              toSource {
                root = ./.;
                fileset = unions [ ./numlockfixd ./numlockfixd.xcodeproj ];
              };
            nativeBuildInputs = [ xcodeHook ];
            installPhase = ''
              mkdir -p $out/bin
              cp Products/Release/numlockfixd $out/bin/
            '';
          };
        });
    };
}
