# SideWeave plugin template

This directory is the starter for the standalone repository `suzikuo/sideweave-plugin-template`. It builds a small web-sandbox plugin ZIP. Copy the directory contents into a new repository, replace the example metadata and UI, then push a version tag to create a signed GitHub Release.

## Package manifest

Edit `manifest.json` before publishing:

- Use a stable lowercase `id` containing letters, digits, `_` or `-`.
- Keep `type` as `web` for this sandbox example. Native packages use `type: "native"`, a supported native runtime, a backend path and `requires_trust: true`.
- Declare host API permissions under `capabilities`; these are the existing SideWeave permission IDs. The host still reads old `permissions` manifests.
- Set your marketplace `publisher` ID and `key_id`. The signed archive manifest must match the marketplace entry.
- Use relative paths for the UI and assets.

## Publish a signed version

1. Generate a dedicated CI keypair with `minisign -G -W -s publisher.key -p publisher.pub`. `-W` creates an unencrypted key so GitHub Actions can sign non-interactively; keep the private key only in the repository secret and an offline backup.
2. Open a pull request to `suzikuo/sideweave-marketplace` adding your publisher and public key to `publishers.json`.
3. Configure repository secret `MINISIGN_SECRET_KEY` and repository variable `MINISIGN_PUBLIC_KEY` (the public key's base64 payload) in this plugin repository. The workflow checks that the public key matches the secret before signing. Do not configure a password secret; Minisign's `-P` option is for public-key verification, not signing passwords.
4. Set `manifest.json` to the version being released and push the matching `v<version>` tag.
5. Add the generated ZIP, `.minisig` and `.sha256` URLs to a marketplace pull request. Keep `latest` pointed at the selected version.

The Release workflow builds a ZIP, signs it, writes a checksum and creates a GitHub Release. It does not execute plugin code. The marketplace validator also downloads packages without executing them.

## Native plugin SDK

The example is a web plugin and needs no Rust SDK. For native Rust packages, use the public SDK crates in `sidebar-tauri` (`crates/plugin-api`, `crates/plugin-sdk`, `crates/plugin-ipc`) as Git dependencies pinned to a reviewed tag. These crates retain their `agile-tiles-*` package names for compatibility. The SDK source can move to a smaller standalone repository later without changing plugin IDs or manifests.

Native code can access the host system directly. `capabilities` describes requested host API access; it does not sandbox the native binary.
