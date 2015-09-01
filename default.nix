with import <nixpkgs> {};

let

  nixops = (import ./nixops/release.nix {}).build.x86_64-linux;

in

stdenv.mkDerivation {
  name = "hydra-provisioner";

  buildInputs = with python2Packages; [ wrapPython python ];

  pythonPath = [ nixops nixUnstable ];
  
  unpackPhase = "true";
  buildPhase = "true";

  installPhase =
    ''
      mkdir -p $out/bin
      cp ${./hydra-provisioner} $out/bin/hydra-provisioner
      wrapPythonPrograms
    '';
}