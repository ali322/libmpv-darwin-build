{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
}:

let
  name = "libplacebo";
  version = "6.338.2";
  
  variants = import ../../utils/constants/variants.nix;
  oses = import ../../utils/constants/oses.nix;
  callPackage = pkgs.lib.callPackageWith {
    inherit
      pkgs
      os
      arch
      variant
      ;
  };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.python3
  ];

  pname = import ../../utils/name/package.nix name;
  src = pkgs.fetchFromGitLab {
    owner = "videolan";
    repo = "libplacebo";
    rev = "v${version}";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # 需要替换为实际的 hash
  };
in
pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${variant}-${version}";
  pname = pname;
  inherit version;
  inherit src;
  enableParallelBuilding = true;
  inherit nativeBuildInputs;

  mesonFlags = [
    "--buildtype=release"
    "-Dvulkan=disabled"
    "-Dshaderc=disabled"
    "-Dglslang=disabled"
    "-Ddemos=false"
    "-Dtests=false"
    "-Dbenchmark=false"
    "-Dd3d11=disabled"
  ];

  configurePhase = ''
    meson build \
      --cross-file ${crossFile} \
      --native-file ${nativeFile} \
      "''${mesonFlags[@]}"
  '';

  buildPhase = ''
    ninja -C build
  '';

  installPhase = ''
    ninja -C build install
  '';
} 