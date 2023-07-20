{ lib, stdenv, stdenv9, cmake, fetchFromGitHub, fetchurl, fetchgit, fetchpatch
, fmt_8
, stduuid
, libuuid
, curl
, libgccjit
, libjpeg
, c-blosc
, bison  # cmake
, flex  # cmake
, libcgroup
, icu
, libxcrypt
, boost
, jsoncpp
, lua53Packages
, libmicrohttpd
, opensubdiv
, openexr
, tbb
, openvdb
, cppunit
, ispc
, log4cplus
, embree
, opencolorio
, openimageio
, openimagedenoise
, usd
, random123
, python3
}:
let
  c-blosc-1-20-1 = (c-blosc.override (old: {inherit stdenv;})).overrideAttrs (super: rec {
    version = "1.20.1";

    src = fetchFromGitHub {
      owner = "Blosc";
      repo = "c-blosc";
      rev = "a44e961498cdca2eb893fa897cd15dd007fad496";
      sha256 = "sha256-eiih3yyB3Ek+udsr1kDrJ3AL8c+OYffVkp9edF7Mfig=";
    };
  });
  boost-1-73-0 = (boost.override rec {
    enablePython = true;
    python = python3;
    inherit stdenv;
  }).overrideAttrs (super: rec {
    version = "1.73.0";
    src = fetchurl {
      urls = [
        "mirror://sourceforge/boost/boost_${builtins.replaceStrings ["."] ["_"] version}.tar.bz2"
        "https://boostorg.jfrog.io/artifactory/main/release/${version}/source/boost_${builtins.replaceStrings ["."] ["_"] version}.tar.bz2"
      ];
      # SHA256 from http://www.boost.org/users/history/version_1_73_0.html
      sha256 = "4eb3b8d442b426dc35346235c8733b5ae35ba431690e38c6a8263dce9fcbb402";
    };
  });
  jsoncpp-0-7 = (jsoncpp.override (old: {inherit stdenv;})).overrideAttrs (super: rec {
    version = "0.7.0";
    src = fetchFromGitHub {
      owner = "open-source-parsers";
      repo = "jsoncpp";
      rev = version;
      hash = "sha256-yV/i+rI7L77vtXb9WU+HSSx8WK7k/0Z0NqHMrVahBzY=";
    };
    unpackPhase = ''
      cp -a ${src} ${src.name}
      chmod -R +w ${src.name}
      export sourceRoot=${src.name}
    '';
    cmakeFlags = super.cmakeFlags ++ [
      "-DJSONCPP_WITH_TESTS=OFF"
    ];
  });
  opensubdiv-3-4-3 = (opensubdiv.override (old: {inherit stdenv;})).overrideAttrs (super: rec {
    version = "3.4.3";

    src = fetchFromGitHub {
      owner = "PixarAnimationStudios";
      repo = "OpenSubdiv";
      rev = "v${lib.replaceStrings ["."] ["_"] version}";
      sha256 = "sha256-eYL/7sbmVWwYdfmzlYVZAxj7hBx7Kjly2lv5/8W79n4=";
    };
  });
  openimagedenoise-m =
  let
    tbb=tbb-2020-3;
  in (openimagedenoise.override (super: {
    inherit stdenv tbb;
  })).overrideAttrs (super: rec{
    cmakeFlags = [
      "-DTBB_ROOT=${tbb}"
      "-DTBB_INCLUDE_DIR=${tbb}/include"
    ];
  });
  openexr-m = openexr.override {inherit stdenv;};
  opencolorio-m = opencolorio.override {inherit stdenv;};
  openimageio-m = (openimageio.override (super: {
    inherit stdenv;
    boost = boost-1-73-0;
    opencolorio = opencolorio-m;
    openexr = openexr-m;
    fmt = fmt_8;
  })).overrideAttrs (super: rec {
    version = "2.2.20.0";
    src = fetchFromGitHub {
      owner = "OpenImageIO";
      repo = "oiio";
      rev = "v${version}";
      hash = "sha256-kSQwNR+s54ixombGI+MM6asJ0pWy9qu7NfekE4OGb8o=";
    };
  });
  openvdb-8-2-0 = (openvdb.override (old: {
    inherit stdenv;
    tbb=tbb-2020-3;
    boost=boost-1-73-0;
  })).overrideAttrs (super: rec {
    version = "8.2.0";
    src = fetchFromGitHub {
      owner = "AcademySoftwareFoundation";
      repo = "openvdb";
      rev = "v${version}";
      sha256 = "sha256-M5eg7AbJkI1G7fZrx9sCPtIZrvCozySu7mhyC08ypiA=";
    };
  });
  usd-m = (usd.override {
    inherit stdenv;
    python = python3;
    boost = boost-1-73-0;
    tbb = tbb-2020-3;
    doUsdView = false;
  }).overrideAttrs (super: rec {
    version = "22.05";
    src = fetchurl {
      url = "https://github.com/PixarAnimationStudios/OpenUSD/archive/refs/tags/v${version}.tar.gz";
      sha256 = "sha256-5XdD58tJTQfub7HlGl0z0e8UxSxLw+4THXPKZdkx/S0=";
    };

    # todo:  supposedly not needed starting from https://github.com/PixarAnimationStudios/OpenUSD/releases/tag/v22.08
    postUnpack = if
    (builtins.compareVersions version "22.08" < 0) &&
    (builtins.compareVersions stdenv.cc.libc.version "2.34" >= 0)
      then ''
      sed -i.bak  -e 's/.if !defined.ARCH_OS_WINDOWS./#if 0/' -e 's/.if defined.ARCH_COMPILER_GCC.*/#if 0/' -e 's/defined.ARCH_COMPILER_CLANG.//' -e 's/.if defined.ARCH_OS_LINUX./#if 0/' -e 's/.if !defined.ARCH_OS_LINUX./#if 1/' OpenUSD-${version}/pxr/base/arch/mallocHook.cpp
    '' else "";

    buildInputs = super.buildInputs ++ [
      libxcrypt
    ];
  });
  ispc-1-14-1 = (ispc.override (old: {inherit stdenv;})).overrideAttrs (super: rec {
    version = "1.14.1";

    src = fetchFromGitHub {
      owner  = super.pname;
      repo   = super.pname;
      rev    = "v${version}";
      sha256 = "sha256-PAD5oJkKzR+nsu7/qE/07c7AhH3m18g857OL1U8+3wk=";
    };
  });
  tbb-2020-3 = (tbb.override (old: {inherit stdenv;})).overrideAttrs (super: rec {
    outputs = [ "out" ];  # cuz moonray's FindTBB cmake looks in one place (or me stopid, try TBB_ROOT cmake var)
  });
  log4cplus-1-1-2 = (log4cplus.override (old: {inherit stdenv;})).overrideAttrs (super: rec {
    version = "1.1.2";

    src = fetchurl {
      url = "mirror://sourceforge/log4cplus/log4cplus-${version}.tar.bz2";
      sha256 = "sha256-xG1WyWhz3LUleRtepjnRQV50sd6Z1RtlczbLbrty7ZM=";
    };
  });
  lua-m = lua53Packages.lua.override (super: {inherit stdenv;});

  embree-patched = embree.overrideAttrs (super: {
    patches = [
      (fetchpatch {
        url = "https://raw.githubusercontent.com/dreamworksanimation/openmoonray/a212d261df2f9b198baf40c96fc53f6a87c56414/building/embree_missing_type.patch";
        hash = "sha256-Z0uWAE8LyTZlZ7oTy5WTjYbusV3a75Tp9Ju8NCkLNGc=";
      })
    ];
  });

  hdMoonrayAdaptersJsonPatch = ./hdMoonrayAdapters_json.patch;
  setupShPatch = ./setup_sh.patch;
in stdenv9.mkDerivation rec {
  pname = "openmoonray";
  version = "1.2.0.0";

  src = fetchgit {
    # owner = "dreamworksanimation";
    # repo="openmoonray";
    # rev = "v${version}";
    url = "https://github.com/dreamworksanimation/openmoonray";
    rev = "a212d261df2f9b198baf40c96fc53f6a87c56414";
    hash = "sha256-x5u+/dFk2TxnJSBqTmL+jk4EUwY5yKja3gC/I6l/Gb0=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    stduuid
    libuuid
    curl.dev
    libgccjit  # for libatomic
    libjpeg
    c-blosc-1-20-1
    bison
    flex
    libcgroup
    icu
    libxcrypt
    boost-1-73-0
    jsoncpp-0-7
    lua-m
    libmicrohttpd
    opensubdiv-3-4-3
    openexr-m
    tbb-2020-3
    openvdb-8-2-0
    cppunit
    ispc
    log4cplus-1-1-2
    embree-patched
    opencolorio
    openimageio-m
    openimagedenoise-m
    usd-m
    random123
    python3
  ];

  hardeningDisable = [ "all" ];

  preBuild = ''
    patchShebangs --build $(grep -rl '#!/bin' ..)
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -fpermissive -fabi-version=0"
  '';

  cmakeFlags = [
    "-DBUILD_QT_APPS=NO"
    "-DMOONRAY_USE_CUDA=NO"
  ];

  postInstall = ''
    patch $out/plugin/usd/hdMoonrayAdapters/plugInfo.json ${hdMoonrayAdaptersJsonPatch}
    patch $out/scripts/setup.sh ${setupShPatch}
    sed -i 's#%USD_LIB%#'"${usd-m}/lib/${python3.libPrefix}/site-packages"'#g' $out/scripts/setup.sh

    bash $out/scripts/setup.sh  # to generate shader descriptions
  '';
}
