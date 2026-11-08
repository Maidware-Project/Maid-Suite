{
  description = "Maid Suite - unified front end for Maidware tools (Maidware)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
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
          dontBuild = true;
          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/share/maid-suite $out/share/applications
            cp -a bin libexec gui $out/share/maid-suite/
            chmod +x $out/share/maid-suite/bin/* $out/share/maid-suite/libexec/au/* $out/share/maid-suite/libexec/helper/* $out/share/maid-suite/libexec/phone/* 2>/dev/null || true
            makeWrapper $out/share/maid-suite/bin/maid-suite.sh $out/bin/maid-suite \
              --prefix PATH : ${runtimePath}
            if [ -f $out/share/maid-suite/bin/maid-suite-gui ]; then
              makeWrapper $out/share/maid-suite/bin/maid-suite-gui $out/bin/maid-suite-gui \
                --prefix PATH : ${runtimePath}:${py}/bin \
                --set PYTHONPATH $out/share/maid-suite/gui
            fi
            [ -d desktop ] && cp -a desktop/*.desktop $out/share/applications/ 2>/dev/null || true
            cp -a README.md LICENSE THIRD-PARTY-NOTICES.md $out/share/maid-suite/ 2>/dev/null || true
            runHook postInstall
          '';
          postFixup = ''
            for f in $out/bin/maid-suite-gui; do [ -f "$f" ] && wrapQtApp "$f" || true; done
          '';
          meta = with pkgs.lib; {
            description = "unified TUI/GUI front end for Maidware tools";
            homepage = "https://github.com/Maidware-Project/Maid-Suite";
            license = licenses.gpl3Plus;
            platforms = platforms.linux;
            mainProgram = "maid-suite";
          };
        };
      in {
        packages.default = maid-suite;
        packages.maid-suite = maid-suite;
        apps.default = { type = "app"; program = "${maid-suite}/bin/maid-suite"; };
        apps.gui = { type = "app"; program = "${maid-suite}/bin/maid-suite-gui"; };
      }
    ) // {
      homeManagerModules.default = { config, lib, pkgs, ... }: {
        options.programs.maid-suite.enable = lib.mkEnableOption "Maid Suite (Maidware)";
        config = lib.mkIf config.programs.maid-suite.enable {
          home.packages = [ self.packages.${pkgs.system}.default ];
        };
      };
    };
}
