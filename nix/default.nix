{
  stdenvNoCC,
  lib,
  makeWrapper,

  # dependencies
  go-toml,
  jq,
  enry,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "ash";
  src = lib.cleanSource ../.;

  phases = "installPhase";

  buildInputs = [makeWrapper go-toml];

  dependencies = [
    go-toml
    jq
    enry
  ];

  installPhase = ''
    cd "$src"
    mkdir -p "$out/bin" "$out/share"

    cp -r share/linguist.tsv "$out/share/"
    tomljson share/ash.toml > "$out/share/ash.json"

    install --mode +x "bin/a.sh" "$out/bin/a.sh.unwrapped"
    makeWrapper "$out/bin/a.sh.unwrapped" "$out/bin/a.sh" \
       --prefix PATH : ${lib.makeBinPath finalAttrs.dependencies}
  '';

  meta.mainProgram = "a.sh";
})
