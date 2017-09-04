{ pkgs ? import <nixpkgs> {}
, nixops ? pkgs.nixops
}:

with pkgs;

stdenv.mkDerivation {
  name = "hydra-provisioner";

  buildInputs = with python2Packages; [ wrapPython python nixops ];

  pythonPath = [ nixops nixUnstable ] ++ nixops.pythonPath;

  unpackPhase = "true";
  buildPhase = "true";

  installPhase =
    ''
      mkdir -p $out/bin $out/share/nix/hydra-provisioner
      cp ${./hydra-provisioner} $out/bin/hydra-provisioner
      cp ${./auto-shutdown.nix} $out/share/nix/hydra-provisioner/auto-shutdown.nix
      wrapPythonPrograms
    '';
}
