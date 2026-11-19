#!/usr/bin/env bash
# Compatibility shim for "powershell" on Linux CI.
#
# gemuera-c#.csproj shells out to:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "$aar='...aar'; ... Add-Type
#     -AssemblyName System.IO.Compression.FileSystem; ... extract jni/arm64-v8a/libe_sqlite3.so"
#
# pwsh 7.6 on Linux cannot load the desktop-only System.IO.Compression.FileSystem
# assembly, so that script fails. If the invocation mentions the SQLitePCLRaw .aar,
# do the extraction with python3; otherwise delegate to the real pwsh.
set -uo pipefail

# Deliberately avoid matching a literal "$aar": in a regex "\$" is an
# end-of-line anchor in some contexts and silently never matches.
aar=$(printf '%s' "$*" | grep -oE "/[A-Za-z0-9._/+~-]*\.aar" | head -1)

if [ -n "${aar:-}" ] && [ -f "$aar" ]; then
  out="${PWD}/export/NativeLibs/android/arm64-v8a"
  python3 - "$aar" "$out" <<'PY'
import os, shutil, sys, zipfile
aar, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
target = 'jni/arm64-v8a/libe_sqlite3.so'
with zipfile.ZipFile(aar) as z:
    names = z.namelist()
    if target not in names:
        sys.stderr.write('shim: %s not in %s\n' % (target, aar))
        sys.exit(1)
    with z.open(target) as src, open(os.path.join(out, 'libe_sqlite3.so'), 'wb') as dst:
        shutil.copyfileobj(src, dst)
print('shim: extracted libe_sqlite3.so ->', out)
PY
  exit $?
fi

exec pwsh "$@"
