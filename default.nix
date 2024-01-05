{ stdenv, lib, fetchurl, innoextract, parted, util-linux, dosfstools, mtools, ... }:

let
  bios = stdenv.mkDerivation rec {
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
  };
in stdenv.mkDerivation rec {
  name = "usbdisk";
  version = bios.version;

  src = ./.;

  nativeBuildInputs = [
    parted
    util-linux
    dosfstools
    mtools
  ];

  doUnpack = false;
  buildPhase = ''
    img=${name}-${version}.iso
    gap=8
    blocks=$(du -B 512 --summarize --apparent-size ${bios} | awk '{ print $1 }')
    blocks=$(( 2 * blocks ))
    size=$(( 512 * blocks + gap * 1024 * 1024 + 34*512))
    truncate -s $size $img
    sfdisk $img <<EOF
      label: gpt
      start=''${gap}M, size=$blocks, type=uefi
    EOF

    eval $(partx $img -o START,SECTORS --nr 1 --pairs)
    truncate -s $(( SECTORS * 512 )) part.img
    mkfs.vfat part.img
    mcopy -spvm -i ./part.img ${bios}/EFI "::/EFI"
    mcopy -spvm -i ./part.img ${bios}/Flash "::/Flash"

    dd conv=notrunc if=part.img of=$img seek=$START count=$SECTORS
    rm -fr part.img
  '';

  installPhase = ''
    mkdir $out
    mv ${name}-${version}.iso $out/
  '';
}
