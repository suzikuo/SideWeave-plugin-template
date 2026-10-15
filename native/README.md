# Native DLL plugin starter

This is a standalone Windows `dynamic_library` plugin project. It does not inherit the SideWeave host or official-plugin Cargo workspace. The package contains a Rust DLL, root `manifest.json`, and the plugin's own UI.

## Start developing

1. Copy this `native/` directory into your plugin repository.
2. Change the plugin ID in `manifest.json` and `src/lib.rs`; keep the package version in `Cargo.toml` and `manifest.json` in sync.
3. Replace the sample UI and handler. UI calls the backend through `window.agileTiles.plugin.call(method, payload)`.
4. Add only the host API capabilities the plugin uses to `manifest.json`. Keep `requires_trust: true` for Native packages.
5. Review the pinned SideWeave revision in `Cargo.toml`. Keep `sideweave-plugin-api` and `sideweave-plugin-sdk` on the same revision, and commit the generated `Cargo.lock`.

Build an unsigned ZIP for local testing:

```powershell
.\tools\package.ps1
```

Import `dist/<plugin-id>-<version>.zip` from the SideWeave plugin center. The ZIP root contains `manifest.json`, `plugin.dll`, and `ui/`.

## Publish a signed version

1. Generate a dedicated Minisign keypair. Keep the private key outside this repository and back it up offline.
2. Register your publisher ID and public key in `publishers.json` in `suzikuo/SideWeave-Marketplace`. Copy the public key payload recorded there.
3. Set `publisher` and `key_id` in `manifest.json`, increment the version in both `manifest.json` and `Cargo.toml`, then run:

   ```powershell
   .\tools\release-local.ps1 `
     -SigningKeyPath 'C:\keys\publisher.key' `
     -ExpectedPublicKeyPayload '<base64-public-key-payload>'
   ```

4. Upload the ZIP, `.minisig`, and `.sha256` files from `dist/` to a GitHub Release.
5. Add those exact asset URLs to the Marketplace catalog and run its validator.

The scripts prepare and sign release assets; they do not publish GitHub Releases or Marketplace changes.

## Runtime contract

The sample declares `runtime: dynamic_library`, `backend: plugin.dll`, and `requires_trust: true`. The SDK macro exports the native entry point expected by SideWeave. Protocol types come from `sideweave-plugin-api`; host services and the `Plugin` trait come from `sideweave-plugin-sdk`. Do not depend on `src-tauri`, the host runtime crate, or Tauri types.

Native code runs with the user's system access. `capabilities` declares host API use; it is not a sandbox. For an out-of-process plugin, use `runtime: external_process`, add `sideweave-plugin-ipc`, and package an executable instead of this DLL.
