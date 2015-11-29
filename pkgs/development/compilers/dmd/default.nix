{ stdenv, callPackage, fetchurl, unzip, which, makeWrapper, gcc }:

let
  bootstrap = callPackage ./dmd.2.067.1.nix { };
in

stdenv.mkDerivation rec {
  version = "2.069.1";
  name = "dmd-${version}";

  src = fetchurl {
    url = "http://downloads.dlang.org/releases/2015/dmd.${version}.zip";
    sha256 = "1g1sff6zp8cnzrlffwjfh0ff2y2ijhd558nz5fhbwwffrjgz4wwc";
  };

  buildInputs = [ unzip which makeWrapper ];

  # Allow to use "clang++", commented in Makefile
  postPatch = stdenv.lib.optionalString stdenv.isDarwin ''
      substituteInPlace src/dmd/posix.mak --replace g++ clang++
  '';

  # Buid and install are based on http://wiki.dlang.org/Building_DMD
  buildPhase = ''
      cd src/dmd
      make -f posix.mak INSTALL_DIR=$out HOST_DC=${bootstrap}/bin/dmd
      export DMD=$PWD/dmd
      cd ../druntime
      make -f posix.mak INSTALL_DIR=$out DMD=$DMD
      cd ../phobos
      make -f posix.mak INSTALL_DIR=$out DMD=$DMD
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

      wrapProgram $out/bin/dmd --prefix PATH ":" "${gcc}/bin/"

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
