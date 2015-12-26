{ stdenv, fetchgit, dmd }:

let
  version = "0.7.3";
in stdenv.mkDerivation rec {
  name = "dcd-${version}";

  # Heavy use of submodules
  src = fetchgit {
    url = https://github.com/Hackerpilot/DCD.git;
    rev = "f8fc736663b8c5636b7651b462a383cd56d9a0f5";
    sha256 = "1xc873lvbpwm7npfwg708czf9qi2chbbv3dgcz5azh6z1898qq0r";
    fetchSubmodules = true;
  };

  buildInputs = [ dmd ];

  patchPhase = ''
    # githash would try to run "git log" which does not work with
    # the sources anymore, simulate it with echo below.
    substituteInPlace makefile --replace ": githash" ":"
    echo ${src.rev} > githash.txt
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/dcd-client $out/bin
    cp bin/dcd-server $out/bin

    mkdir -p $out/share/man
    cp -r man1 $out/share/man/
  '';

  meta = with stdenv.lib; {
    description = "An auto-complete program for the D programming language";
    homepage = https://github.com/Hackerpilot/DCD;
    license = licenses.gpl3;
    maintainers = with maintainers; [ johbo ];
    platforms = platforms.unix;
  };
}
