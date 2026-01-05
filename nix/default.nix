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

    install --mode +x "bin/a.sh" "$out/bin/a.sh.unwrapped"
    makeWrapper "$out/bin/a.sh.unwrapped" "$out/bin/a.sh" \
       --prefix PATH : ${lib.makeBinPath finalAttrs.dependencies}
  '';

  meta.mainProgram = "a.sh";
})
