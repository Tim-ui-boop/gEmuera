#!/usr/bin/env bash
# Compatibility shim for "powershell" on Linux CI.
#
# gemuera-c#.csproj shells out to:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "$aar='...aar'; ... Add-Type
#     -AssemblyName System.IO.Compression.FileSystem; ... extract jni/arm64-v8a/libe_sqlite3.so"
#
# pwsh 7.6 on Linux cannot load the desktop-only System.IO.Compression.FileSystem
# assembly, so that script fails. If the invocation is the .aar extraction, do it
# with python3 instead; otherwise delegate to the real pwsh.
set -uo pipefail

aar=$(printf '%s' "$*" | grep -o "\$aar='[^']*'" | sed "s/^\$aar='//;s/'$//")

if [ -n "${aar:-}" ] && [ -f "$aar" ]; then
  out="${PWD}/export/NativeLibs/android/arm64-v8a"
  python3 - "$aar" "$out" <<'PY'
import os, shutil, sys, zipfile
aar, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
with zipfile.ZipFile(aar) as z:
    with z.open('jni/arm64-v8a/libe_sqlite3.so') as src:
        with open(os.path.join(out, 'libe_sqlite3.so'), 'wb') as dst:
            shutil.copyfileobj(src, dst)
print('shim: extracted libe_sqlite3.so ->', out)
PY
  exit $?
fi

exec pwsh "$@"
