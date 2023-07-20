{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    myusd = {
      url = "github:pedohorse/usd-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    random123pkg = {
      url = "github:pedohorse/random123-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, myusd, random123pkg }:
  let
    stdenv9 = pkgs.overrideCC pkgs.stdenv (pkgs.wrapCCWith rec {
      cc = pkgs.gcc9.cc;
      libcxx = pkgs.gcc.cc.lib;
    });

    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    python3 = pkgs.python38;
    random123 = random123pkg.packages.x86_64-linux.random123;

  in {
    packages.x86_64-linux = rec {
      default = openmoonray;
      openmoonray = pkgs.callPackage ./. {
        inherit python3 random123;
        usd = myusd.packages.x86_64-linux.pixar-usd;
        stdenv = pkgs.stdenv;
        stdenv9 = stdenv9;
        boost = pkgs.boost175;
      };
    };
  };
}
