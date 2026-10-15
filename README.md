# SideWeave plugin templates

This repository contains three independent plugin starters:

- The **Web plugin** starter is at the repository root. It runs in SideWeave's web sandbox.
- The **Native DLL plugin** starter is in [`native/`](native/README.md). It uses a standalone Cargo project and packages its own backend and UI.
- The **Skin plugin** starter is in [`skin/`](skin/README.md). It provides separate sidebar, detail, control and preview pages, plus package and signing scripts.

Choose the Web or Native runtime, or build a Skin package, and follow its README. All three use the same publisher directory, signed release assets, and Marketplace catalog contract. Skins appear in the Marketplace `skins` collection with `type: "skin"`.

## Web package manifest

Edit manifest.json before publishing:

- Use a stable lowercase id containing letters, digits, underscore or hyphen.
- Keep type as web for this sandbox example. Native packages require a supported runtime, backend path and requires_trust: true.
- Declare host API permissions under capabilities. The host still reads old permissions manifests.
- Set publisher and key_id to match publishers.json in the marketplace.
- Use relative paths for the UI and assets.

## Publish a signed Web version locally

1. Generate a dedicated keypair with minisign -G -W -s publisher.key -p publisher.pub. Keep the private key outside the repository and make an offline backup.
2. Add your publisher ID and public key to publishers.json in suzikuo/SideWeave-Marketplace, then push the change. Record the base64 payload from the last line of publisher.pub.
3. Set manifest.json to the version being released. From PowerShell, run:

       .\tools\release-local.ps1 -Version 1.2.0 -SigningKeyPath 'C:\keys\publisher.key' -ExpectedPublicKeyPayload '<payload>' -MinisignExe 'C:\tools\minisign.exe'

4. Create a GitHub Release with tag v<version> and upload the ZIP, .minisig and .sha256 files from dist.
5. Add the exact asset URLs to marketplace.json in a follow-up commit. Keep latest pointed at the selected version and run the marketplace validator locally before pushing.

The local script packages and signs the ZIP; it does not publish or execute plugin code.

## Native plugin SDK

The Native starter is a Windows `dynamic_library` plugin. Its Cargo project depends directly on `sideweave-plugin-api` for protocol types and `sideweave-plugin-sdk` for host services, pinned to one reviewed SideWeave Git revision. It includes scripts to build `plugin.dll`, package it with the manifest and UI, and prepare signed release assets.

Native code can access the host system directly. `capabilities` describes requested host API access; it does not sandbox the native binary. For an out-of-process plugin, use the `external_process` runtime and add `sideweave-plugin-ipc`.
