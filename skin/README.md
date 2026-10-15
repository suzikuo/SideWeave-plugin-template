# Skin plugin starter

This folder is a standalone SideWeave skin package starter. Copy it to a repository of your own, then update `manifest.json`, `skin.css`, and the four HTML pages in `ui/`.

## Package contract

- Keep `manifest.json` at the ZIP root.
- Use a unique lowercase `id`, semantic `version`, `type: "skin"`, your Marketplace `publisher`, and an active `key_id`.
- Skins run as HTML and CSS assets. They do not declare executable capabilities or require native trust.
- Keep `skinUi.assetRoot` and each entry path package-relative. The sidebar, detail, control and preview entries must all exist.
- Optional `appearanceDefaults` values must be between `0` and `1`.

Each page is loaded in an isolated iframe. The host injects `window.sideweaveSkin`; use its `onContext`, `onEvent`, and `call` methods to read host state or request a supported host action. Existing skins can keep using the `window.agileTilesSkin` compatibility alias. The example script is safe to run in a plain browser while developing.

## Build a ZIP for local import

From this directory, run:

```powershell
.\tools\package.ps1
```

The resulting `dist/<id>-<version>.zip` has `manifest.json` at its root. Import it through the SideWeave plugin/skin center to preview it.

## Prepare signed release assets

Register your publisher and public key in `publishers.json`, then prepare signed assets:

```powershell
.\tools\release-local.ps1 `
  -Version 1.0.0 `
  -SigningKeyPath 'C:\keys\publisher.key' `
  -ExpectedPublicKeyPayload '<base64-public-key-payload>'
```

This creates the ZIP, `.minisig`, and `.sha256` files in `dist/`. Upload them to a GitHub Release, then add the asset URLs under the Marketplace `skins` collection. The local script does not publish a Release or change the Marketplace.
