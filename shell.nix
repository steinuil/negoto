{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [ urweb sass ];
  buildInputs = with pkgs; [ sqlite openssl icu ];
}
