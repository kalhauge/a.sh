{
  stdenvNoCC,
  lib,
  makeWrapper,
  toml2json,
  jq,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "ash";
  src = lib.cleanSource ../.;

  phases = "installPhase";

  buildInputs = [makeWrapper toml2json];

  dependencies = [
    toml2json
    jq
  ];

  installPhase = ''
    cd "$src"
    mkdir -p "$out/bin" "$out/share"

    cp -r share/linguist.tsv "$out/share/"
    toml2json -p share/ash.toml > "$out/share/ash.json"

    for file in bin/*.sh; do
      exec="$out/$file"
      install --mode +x "$file" "$exec"
      makeWrapper $exec ''${exec%.sh} \
         --prefix PATH : ${lib.makeBinPath finalAttrs.dependencies}
    done
  '';
})
