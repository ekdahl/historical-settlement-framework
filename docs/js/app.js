async function boot() {
  const response = await fetch('../../config.json');
  const config = await response.json();

  document.title = config.title;
  document.getElementById('title').textContent = config.title;

  await startApp(config);
}

boot();

function createLayer(cfg) {
  switch (cfg.type) {
    case "xyz":
      return L.tileLayer(
        cfg.url,
        cfg.options ?? {}
      );

    case "wms":
      return L.tileLayer.wms(
        cfg.url,
        cfg.options ?? {}
      );

    default:
      throw new Error(`Unknown layer type: ${cfg.type}`);
  }
}