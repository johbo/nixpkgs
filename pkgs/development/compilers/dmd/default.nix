{ stdenv, callPackage, fetchurl, unzip, curl, which, tzdata, makeWrapper }:

let
  bootstrap = callPackage ./dmd.2.067.1.nix { };
in

stdenv.mkDerivation rec {
  version = "2.069.2";
  name = "dmd-${version}";

  src = fetchurl {
    url = "http://downloads.dlang.org/releases/2015/dmd.${version}.zip";
    sha256 = "1k3qh27wfg2x54jqvcv6f5rcnp0d5mjd6n4p1hmazxy9amap9bza";
  };

  buildInputs = [ unzip curl which tzdata makeWrapper ];

  prePatch = ''
      #Ugly hack to fix the hardcoded path to zoneinfo in the source file.
      substituteInPlace src/phobos/std/datetime.d --replace /usr/share/zoneinfo/ ${tzdata}/share/zoneinfo/
      #Ugly hack so the dlopen call has a chance to succeed.
      substituteInPlace src/phobos/std/net/curl.d --replace libcurl.so ${curl}/lib/libcurl.so
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
      substituteInPlace src/dmd/posix.mak \
          --replace g++ clang++ \
          --replace MACOSX_DEPLOYMENT_TARGET MACOSX_DEPLOYMENT_TARGET_
  '';

  # Buid and install are based on http://wiki.dlang.org/Building_DMD
  buildPhase = ''
      cd src/dmd
      make -f posix.mak INSTALL_DIR=$out HOST_DMD=${bootstrap}/bin/dmd BUILD=release
      export DMD=$PWD/dmd
      cd ../druntime
      make -f posix.mak INSTALL_DIR=$out DMD=$DMD BUILD=release
      cd ../phobos
      make -f posix.mak INSTALL_DIR=$out DMD=$DMD BUILD=release
      cd ../..
  '';

  # Test suite fails around too long path
  doCheck = !stdenv.isDarwin;

  checkPhase = ''
    export DMD=$PWD/src/dmd/dmd
    cd src/druntime
    make -f posix.mak unittest DMD=$DMD BUILD=release
    cd ../phobos
    make -f posix.mak unittest DMD=$DMD BUILD=release
    cd ../..
  '';

  installPhase = ''
      cd src/dmd
      mkdir $out
      mkdir $out/bin
      cp dmd $out/bin

      cd ../druntime
      mkdir $out/include
      mkdir $out/include/d2
      cp -r import/* $out/include/d2

      cd ../phobos
      mkdir $out/lib
      ${let bits = if stdenv.is64bit then "64" else "32";
            osname = if stdenv.isDarwin then "osx" else "linux"; in
      "cp generated/${osname}/release/${bits}/libphobos2.a $out/lib"
      }

      cp -r std $out/include/d2
      cp -r etc $out/include/d2

      wrapProgram $out/bin/dmd \
          --prefix PATH ":" "${stdenv.cc}/bin/" \
          --set CC "$""{CC:-$CC""}"

      cd $out/bin
      tee dmd.conf << EOF
      [Environment]
      DFLAGS=-I$out/include/d2 -L-L$out/lib ${stdenv.lib.optionalString (!stdenv.cc.isClang) "-L--no-warn-search-mismatch -L--export-dynamic"}
      EOF
  '';

  meta = with stdenv.lib; {
    description = "D language compiler";
    homepage = http://dlang.org/;
    license = licenses.free; # parts under different licenses
    maintainers = [ stdenv.lib.maintainers.thomad ];
    platforms = platforms.unix;
  };
}
