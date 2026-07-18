{
  stdenvNoCC,
  lib,
  makeWrapper,

  # dependencies
  jq,
  enry,
  toybox,
  bash,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "ash";
  src = lib.cleanSource ../../.;

  nativeBuildInputs = [
    makeWrapper
    bash
  ];

  buildInputs = [
  ];

  dependencies = [
    jq
    enry
    toybox
  ];

  buildPhase = "";

  installPhase = ''
    cd "$src"
    mkdir -p "$out/bin" "$out/share"

    cp -r share/linguist.tsv "$out/share/"
    cp "bin/a.sh" "$out/bin/a.sh.unwrapped"

    patchShebangs --host "$out/bin/a.sh.unwrapped"

    makeWrapper "$out/bin/a.sh.unwrapped" "$out/bin/a.sh" \
       --prefix PATH : ${lib.makeBinPath finalAttrs.dependencies}
  '';

  meta.mainProgram = "a.sh";
})
