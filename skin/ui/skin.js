const bridge = window.sideweaveSkin || window.agileTilesSkin

if (bridge?.onContext) {
  bridge.onContext((context) => {
    document.documentElement.dataset.surface = context.surface || document.body.dataset.surface || 'skin'
  })
}

if (bridge?.onEvent) {
  bridge.onEvent('settingsChanged', (settings) => {
    document.documentElement.dataset.theme = settings.theme || 'default'
  })
}
