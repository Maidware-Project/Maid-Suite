{
  description = "Maid Suite - unified front end for Maidware tools (Maidware)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          py = pkgs.python3.withPackages (ps: [ ps.pyqt6 ]);
          runtimePath = pkgs.lib.makeBinPath [
            pkgs.bash pkgs.coreutils pkgs.curl pkgs.git pkgs.gnugrep pkgs.gnused pkgs.findutils
            pkgs.android-tools pkgs.procps pkgs.util-linux
          ];
          maid-suite = pkgs.stdenv.mkDerivation {
            pname = "maid-suite";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = [ pkgs.makeWrapper pkgs.qt6.wrapQtAppsHook ];
            buildInputs = [ pkgs.qt6.qtbase ];
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/share/maid-suite $out/share/applications
              cp -a bin libexec gui $out/share/maid-suite/
              find $out/share/maid-suite/bin -type f -exec chmod +x {} +
              find $out/share/maid-suite/libexec -type f \( -name '*.sh' -o -path '*/phone/*' -o -path '*/au/update-all.sh' \) -exec chmod +x {} + 2>/dev/null || true
              makeWrapper $out/share/maid-suite/bin/maid-suite.sh $out/bin/maid-suite --prefix PATH : ${runtimePath}
              if [ -f $out/share/maid-suite/bin/maid-suite-gui ]; then
                makeWrapper $out/share/maid-suite/bin/maid-suite-gui $out/bin/maid-suite-gui --prefix PATH : ${runtimePath}:${py}/bin --set PYTHONPATH $out/share/maid-suite/gui
              fi
              [ -d desktop ] && cp -a desktop/*.desktop $out/share/applications/ 2>/dev/null || true
              cp -a README.md LICENSE THIRD-PARTY-NOTICES.md $out/share/maid-suite/ 2>/dev/null || true
              runHook postInstall
            '';
            postFixup = ''
              for f in $out/bin/maid-suite-gui; do [ -f "$f" ] && wrapQtApp "$f" || true; done
            '';
            meta = with pkgs.lib; { description = "unified TUI/GUI front end for Maidware tools"; homepage = "https://github.com/Maidware-Project/Maid-Suite"; license = licenses.gpl3Plus; platforms = platforms.linux; mainProgram = "maid-suite"; };
          };
        in { default = maid-suite; maid-suite = maid-suite; });

      apps = forAllSystems (system: {
        default = { type = "app"; program = "${self.packages.${system}.default}/bin/maid-suite"; };
        gui = { type = "app"; program = "${self.packages.${system}.default}/bin/maid-suite-gui"; };
      });
      checks = forAllSystems (system: { package = self.packages.${system}.default; });

      # easy: imports = [ inputs.maid-suite.homeManagerModules.default ]; programs.maid-suite.enable = true;
      # on NixOS, install Maidware tools declaratively (flakes/home-manager) - Suite detects NixOS and guides you.
      homeManagerModules.default = { config, lib, pkgs, ... }: {
        options.programs.maid-suite = {
          enable = lib.mkEnableOption "Maid Suite (Maidware)";
          package = lib.mkOption { type = lib.types.package; default = self.packages.${pkgs.stdenv.hostPlatform.system}.default; };
        };
        config = lib.mkIf config.programs.maid-suite.enable { home.packages = [ config.programs.maid-suite.package ]; };
      };
      homeModules = self.homeManagerModules;
      nixosModules.default = { lib, ... }: { options.programs.maid-suite.enableNote = lib.mkEnableOption "Maid Suite (use home-manager module)"; };
    };
}
