{ flakePath ? null, hostnamePath ? "/etc/hostname" }:

let
  inherit (builtins) getFlake head split currentSystem readFile pathExists filter fromJSON;
  registryPath = /etc/nix/registry.json;
  selfFlake =
    if pathExists registryPath
    then filter (it: it.from.id == "self") (fromJSON (readFile registryPath)).flakes
    else [ ];

  flakePath' = toString
    (if flakePath != null
    then flakePath
    else if selfFlake != [ ]
    then (head selfFlake).to.path
    else "/etc/nixos");

  flake = if pathExists flakePath' then getFlake flakePath' else { };
  hostname = if pathExists hostnamePath then head (split "\n" (readFile hostnamePath)) else "";

  nixpkgsFromInputsPath = flake.inputs.nixpkgs.outPath or "";
  nixpkgs = flake.pkgs.${currentSystem}.nixpkgs or (if nixpkgsFromInputsPath != "" then import nixpkgsFromInputsPath { } else { });

  nixpkgsOutput = (removeAttrs (nixpkgs // nixpkgs.lib or { }) [ "options" "config" ]);
in
{ inherit flake; }
// flake
// builtins
// (flake.nixosConfigurations or { })
// flake.nixosConfigurations.${hostname} or { }
// nixpkgsOutput
  // { loadFlake = path: getFlake (toString path); }
