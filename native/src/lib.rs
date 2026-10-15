use sideweave_plugin_api::{
    ErrorCode, PluginError, PluginManifest, PluginRequest, PluginResponse, PluginRuntime,
    PluginTrust, PluginUi, PluginUiKind, API_VERSION, MANIFEST_VERSION,
};
use sideweave_plugin_sdk::{success_response, Plugin, PluginContext};
use serde_json::json;

const PLUGIN_ID: &str = "native-starter";

pub struct NativeStarter {
    manifest: PluginManifest,
}

impl NativeStarter {
    fn new() -> Self {
        Self {
            manifest: PluginManifest {
                manifest_version: MANIFEST_VERSION,
                api_version: API_VERSION,
                id: sideweave_plugin_api::PluginId::new(PLUGIN_ID)
                    .expect("valid static plugin id"),
                name: "Native Starter".into(),
                icon: "ui/icon.svg".into(),
                version: env!("CARGO_PKG_VERSION").into(),
                description: "A starter SideWeave native plugin.".into(),
                author: "Your Name".into(),
                runtime: PluginRuntime::DynamicLibrary,
                backend: Some("plugin.dll".into()),
                trust: PluginTrust::TrustedLocal,
                auto_start: false,
                permissions: Vec::new(),
                ui: Some(PluginUi {
                    entry: "ui/index.html".into(),
                    kind: Some(PluginUiKind::Html),
                    asset_root: "ui".into(),
                    initial_width: Some(580),
                    initial_height: Some(520),
                    ..Default::default()
                }),
                hover_preview: None,
                minimum_host_version: None,
            },
        }
    }
}

impl Default for NativeStarter {
    fn default() -> Self {
        Self::new()
    }
}

sideweave_plugin_sdk::export_plugin_dylib!(NativeStarter);

impl Plugin for NativeStarter {
    fn manifest(&self) -> &PluginManifest {
        &self.manifest
    }

    fn handle(&mut self, request: PluginRequest, _context: &PluginContext) -> PluginResponse {
        let method = request.method.clone();
        match method.as_deref() {
            Some("hello") => success_response(&request, json!({ "message": "Hello from Native" })),
            Some(method) => error_response(
                request,
                ErrorCode::NotFound,
                format!("unknown method: {method}"),
            ),
            None => error_response(
                request,
                ErrorCode::InvalidRequest,
                "missing method".into(),
            ),
        }
    }
}

fn error_response(request: PluginRequest, code: ErrorCode, message: String) -> PluginResponse {
    PluginResponse {
        request_id: request.request_id,
        plugin_id: request.plugin_id,
        ok: false,
        result: serde_json::Value::Null,
        error: Some(PluginError { code, message }),
    }
}
