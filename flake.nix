{
  description = "Panel Widget Group for KDE Plasma 6";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = nixpkgs.lib.genAttrs supportedSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenvNoCC.mkDerivation {
            pname = "kde-panel-widget-group";
            version = "1.0.0";
            src = self;

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              plasmoid_target="$out/share/plasma/plasmoids/com.acomagu.widgetgroup"
              mkdir -p "$plasmoid_target"
              cp -r contents metadata.json "$plasmoid_target/"

              runHook postInstall
            '';
          };
        });
    };
}
