# Förslag: arkitektur för torpinventering / historisk bebyggelse

## Övergripande arkitektur

Dela upp lösningen i två delar:

### 1. Framework-repo (återanvändbart)
Innehåller:

- frontend (HTML, JS, CSS)
- Leaflet-karta
- Bootstrap-layout
- build-script
- JSON-schema
- GeoJSON-generering
- tile-generering

Exempel:

```text
historical-settlement-framework/
  docs/
    index.html
    js/
    css/
  schema/
  scripts/
```

Publiceras normalt inte separat.

### 2. Data-repo (projektspecifikt)

Exempel:

velinga-torpinventering/
  data/
    places/
    maps/

  config.json

  framework/   # git submodule -> historical-settlement-framework

Publiceras via GitHub Pages från:

/framework/docs

URL blir då t.ex.:

https://fredrikekdahl.github.io/velinga-torpinventering/

## Dataformat

### Platser (torp/gårdar)

En mapp per objekt:
```
data/
  places/
    backstugan/
      metadata.json
      text.md
      images/
        001.webp
```

metadata.json
```json
{
  "id": "backstugan",
  "namn": "Backstugan",
  "typ": "torp",
  "platser": [
    {
      "lat": 58.12345,
      "lon": 13.45678,
      "från": 1750,
      "till": 1825
    },
    {
      "lat": 58.12410,
      "lon": 13.46020,
      "från": 1825,
      "till": 1900
    }
  ]
}
```

### Giltiga `typ`

- torp
- gård
- soldattorp
- backstuga
- kvarn
- kyrka
- skola

### Historiska kartor

En mapp per karta:
```
data/
  maps/
    laga_skifte_1827/
      source.json
      map.vrt
      gcps.json
```

Innehåller:

- original-URL till källa (t.ex. Lantmäteriet)
- VRT/GCP (icke-destruktiv georeferering)
- genererade tiles skapas i build-steget

## Build-pipeline

metadata.json + text.md + kartor
        ↓
validering
        ↓
GeoJSON
        ↓
gdal2tiles
        ↓
framework/docs/

GeoJSON används endast som leveransformat, inte som primär lagring.

## Frontend

### Teknik

- Leaflet
- Bootstrap
- egen JS

### UI

- karta i mitten
- sidpanel för info/lager/sök
- tidsslider längst ned

## Lagerkonfiguration (config.json)

Alla kartlager definieras i data-repot:

```json
{
  "title": "Velinga torpinventering",
  "dataPath": "../../data",

  "layers": [
    {
      "id": "lm-topo",
      "name": "Lantmäteriet topo",
      "type": "xyz",
      "url": "...",
      "options": {
        "attribution": "© Lantmäteriet",
        "opacity": 1
      },
      "visible": true
    },
    {
      "id": "histortho60",
      "name": "Historiskt ortofoto 1960",
      "type": "wms",
      "url": "...",
      "options": {
        "layers": "OI.Histortho_60",
        "transparent": true
      },
      "visible": false
    }
  ]
}
```

Alla lager behandlas som jämbördiga (ingen skillnad mellan "base" och "overlay").

## Grundprincip

Framework = motor
Datarepo = forskning/innehåll

Det gör systemet återanvändbart för andra socknar/byar.