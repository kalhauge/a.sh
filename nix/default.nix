{
  stdenvNoCC,
  lib,
  makeWrapper,

  ash-config,

  # dependencies
  jq,
  enry,
  toybox,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "ash";
  src = lib.cleanSource ../.;

  phases = "installPhase";

  buildInputs = [
    makeWrapper
  ];

  dependencies = [
    jq
    enry
    toybox
  ];

  installPhase = ''
    cd "$src"
    mkdir -p "$out/bin" "$out/share"

    cp -r share/linguist.tsv "$out/share/"
    ln -s "${ash-config}" "$out/share/ash.json"

    install --mode +x "bin/a.sh" "$out/bin/a.sh.unwrapped"
    makeWrapper "$out/bin/a.sh.unwrapped" "$out/bin/a.sh" \
       --prefix PATH : ${lib.makeBinPath finalAttrs.dependencies}
  '';

  meta.mainProgram = "a.sh";
})
