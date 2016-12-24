{stdenv, fetchurl, autoreconfHook, pkgconfig, atk, cairo, glib
, gnome_common, gtk, pango
, libxml2Python, perl, intltool, gettext, gtk-mac-integration }:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "gtksourceview-${version}";
  version = "2.10.5";

  src = fetchurl {
    url = "mirror://gnome/sources/gtksourceview/2.10/${name}.tar.bz2";
    sha256 = "c585773743b1df8a04b1be7f7d90eecdf22681490d6810be54c81a7ae152191e";
  };

  patches = optionals stdenv.isDarwin [
    ./0001-Change-IgeMacIntegration-to-GtkOSXApplication.patch
    ./0002-Update-to-gtk-mac-integration-2.0-API.patch
  ];

  buildInputs = [
    pkgconfig atk cairo glib gtk
    pango libxml2Python perl intltool
    gettext
  ] ++ optionals stdenv.isDarwin [
    autoreconfHook gnome_common gtk-mac-integration
  ];

  preConfigure = optionalString stdenv.isDarwin ''
    intltoolize --force
  '';
}
