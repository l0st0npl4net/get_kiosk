#!/bin/bash
#
# Build a distributable GET-KIOSK installer archive.
#
# Produces release/kiosk-installer-<version>-linux-x86_64.zip containing:
#   kiosk-installer      statically linked Linux binary (musl, Debian 13 target)
#   assets/              text payloads read at run time
#   app/                 driver payloads (PPD, filters, vendor binaries)
#   VERSION              build metadata
#
# The zip is meant to be attached to a GitHub release; `start.sh` downloads it
# from there and unpacks it before running the installer.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
TARGET="${TARGET:-x86_64-unknown-linux-musl}"
VERSION="${VERSION:-$(sed -n 's/^version = "\(.*\)"$/\1/p' "$HERE/Cargo.toml" | head -1)}"
NAME="kiosk-installer-${VERSION}-linux-x86_64"
# Stable file name `start.sh` downloads from releases/latest/download/.
STABLE="kiosk-installer-linux-x86_64.zip"
OUT="$HERE/release"
STAGE="$OUT/$NAME"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -n "$VERSION" ] || die "cannot read version from Cargo.toml"

say "target:  $TARGET"
say "version: $VERSION"
say "output:  $OUT/$NAME.zip"

if ! rustup target list --installed | grep -qx "$TARGET"; then
    say "adding Rust target $TARGET"
    rustup target add "$TARGET" || die "cannot add $TARGET"
fi

say "compiling"
cargo build --release --target "$TARGET" --manifest-path "$HERE/Cargo.toml" \
    || die "build failed for $TARGET"

BIN="$HERE/target/$TARGET/release/kiosk-installer"
[ -f "$BIN" ] || die "binary not found at $BIN"

rm -rf "$STAGE"
mkdir -p "$STAGE/assets"

say "staging payload"
install -m 0755 "$BIN" "$STAGE/kiosk-installer"
cp "$HERE"/assets/* "$STAGE/assets/"

# Only the payload the installer reads; drivers, filters and vendor trees.
mkdir -p "$STAGE/app"
for dir in printer terminals fiscal sst; do
    [ -d "$ROOT/app/$dir" ] || die "missing $ROOT/app/$dir"
    cp -r "$ROOT/app/$dir" "$STAGE/app/"
done

cat > "$STAGE/VERSION" <<EOF
version=$VERSION
target=$TARGET
built=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

if command -v strip >/dev/null 2>&1; then
    strip "$STAGE/kiosk-installer" 2>/dev/null || true
fi

say "binary size: $(du -h "$STAGE/kiosk-installer" | cut -f1)"

rm -f "$OUT/$NAME.zip" "$OUT/$STABLE"
if command -v zip >/dev/null 2>&1; then
    (cd "$OUT" && zip -qr "$NAME.zip" "$NAME")
else
    (cd "$OUT" && tar -czf "$NAME.zip" "$NAME")
    say "note: zip is unavailable, wrote a .tar.gz named .zip"
fi

# Versioned archive for the release page, plus the stable name start.sh uses.
cp "$OUT/$NAME.zip" "$OUT/$STABLE"

say "archive: $OUT/$NAME.zip ($(du -h "$OUT/$NAME.zip" | cut -f1))"
say "stable:  $OUT/$STABLE"
say "upload both to the GitHub release; start.sh fetches the stable name"
say "contents:"
unzip -l "$OUT/$NAME.zip" 2>/dev/null | sed -n '1,12p' || true
