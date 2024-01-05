{ stdenv, lib, fetchurl, innoextract, parted, ... }:

stdenv.mkDerivation rec {
  name = "bios";
  version = "1.59";

  src = fetchurl {
    url = "https://download.lenovo.com/pccbbs/mobiles/n3huj18w.exe";
    hash = "sha256-e2ZxDA2XVlOZ1tXXLtb7ZPYs0fTRJ7Ze6E2hy17eV4U=";
  };

  nativeBuildInputs = [
    innoextract
  ];

  unpackPhase = ''
    innoextract $src
  '';

  doBuild = false;

  installPhase = ''
    mkdir --parent $out/{EFI/Boot,Flash}
    cp code\$GetExtractPath\$/Rfs/Usb/Bootaa64.efi $out/EFI/Boot/
    cp -r code\$GetExtractPath\$/Rfs/Fw/* $out/Flash/
  '';
}
