async function boot() {
  const response = await fetch('../../config.json');
  const config = await response.json();

  document.title = config.title;
  document.getElementById('title').textContent = config.title;

  // Initialize theme toggle
  initializeThemeToggle();

  await startApp(config);
}

boot();

async function startApp(config) {
  // Initialize the Leaflet map with center and zoom from config
  const map = L.map('map').setView(config.mapCenter, config.mapZoom);

  const layerList = [];

  // Add layers from config
  if (config.mapLayers && Array.isArray(config.mapLayers)) {
    config.mapLayers.forEach(layerCfg => {
      const layer = createLayer(layerCfg);
      const layerName = layerCfg.name || layerCfg.id || 'Unnamed';

      layerList.push({ name: layerName, layer, config: layerCfg });

      // Add to map if visible
      if (layerCfg.visible) {
        layer.addTo(map);
      }
    });
  }

  // Add custom layer control with opacity sliders
  createLayerControlWithOpacity(map, layerList);

  return map;
}

function createLayerControlWithOpacity(map, layerList) {
  const control = L.Control.extend({
    onAdd: function(map) {
      const container = L.DomUtil.create('div', 'leaflet-control-layers leaflet-control');

      layerList.forEach(({ name, layer, config }) => {
        const layerItem = L.DomUtil.create('div', 'layer-item', container);

        // Layer title on first line
        const title = L.DomUtil.create('div', 'layer-title', layerItem);
        title.textContent = name;

        // Checkbox and slider on second line
        const controls = L.DomUtil.create('div', 'layer-controls', layerItem);

        // Checkbox
        const checkbox = L.DomUtil.create('input', '', controls);
        checkbox.type = 'checkbox';
        checkbox.id = `layer-${name}`;
        checkbox.checked = config.visible;

        checkbox.addEventListener('change', (e) => {
          if (e.target.checked) {
            layer.addTo(map);
          } else {
            map.removeLayer(layer);
          }
        });

        // Opacity slider
        const slider = L.DomUtil.create('input', '', controls);
        slider.type = 'range';
        slider.min = '0';
        slider.max = '100';
        slider.value = (config.options?.opacity ?? 1) * 100;
        slider.style.marginLeft = '8px';

        slider.addEventListener('input', (e) => {
          const opacity = e.target.value / 100;
          layer.setOpacity(opacity);
        });

        L.DomEvent.disableClickPropagation(layerItem);
      });

      return container;
    }
  });

  new control({ position: 'topright' }).addTo(map);
}

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

function initializeThemeToggle() {
  const themeToggle = document.getElementById('themeToggle');
  const htmlElement = document.documentElement;

  // Load saved theme or default to light
  const savedTheme = localStorage.getItem('theme') || 'light';
  htmlElement.setAttribute('data-bs-theme', savedTheme);
  updateThemeIcon(savedTheme);

  // Toggle theme on button click
  themeToggle.addEventListener('click', () => {
    const currentTheme = htmlElement.getAttribute('data-bs-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';

    htmlElement.setAttribute('data-bs-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateThemeIcon(newTheme);
  });
}

function updateThemeIcon(theme) {
  const themeToggle = document.getElementById('themeToggle');
  if (theme === 'dark') {
    themeToggle.innerHTML = '<i class="bi bi-sun-fill"></i>';
  } else {
    themeToggle.innerHTML = '<i class="bi bi-moon-fill"></i>';
  }
}