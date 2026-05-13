import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.geocodeCache = {}
    this.map = null
    this.markers = []

    fetch(this.urlValue)
      .then(r => r.json())
      .then(data => this.initMap(data))
      .catch(err => {
        this.element.innerHTML = '<div class="empty-state" style="padding:2rem;"><p>Failed to load map data.</p></div>'
        console.error("Map error:", err)
      })
  }

  initMap(data) {
    // Initialize Leaflet map with dark theme
    this.map = L.map(this.element, {
      center: [30, 30],
      zoom: 3,
      zoomControl: true
    })

    // Dark map tiles
    L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/">CARTO</a>',
      subdomains: "abcd",
      maxZoom: 19
    }).addTo(this.map)

    // Group by unique places
    const placeMap = {}
    data.forEach(marker => {
      const key = marker.place.toLowerCase().trim()
      if (!placeMap[key]) {
        placeMap[key] = { place: marker.place, people: [] }
      }
      placeMap[key].people.push(marker)
    })

    // Geocode each unique place and add markers
    const places = Object.values(placeMap)
    this.geocodeAndPlot(places, 0)
  }

  geocodeAndPlot(places, index) {
    if (index >= places.length) {
      // Fit map to markers
      if (this.markers.length > 0) {
        const group = L.featureGroup(this.markers)
        this.map.fitBounds(group.getBounds().pad(0.2))
      }
      return
    }

    const place = places[index]
    const key = place.place.toLowerCase().trim()

    // Throttle geocoding requests (Nominatim rate limit: 1/sec)
    setTimeout(() => {
      this.geocode(place.place).then(coords => {
        if (coords) {
          const hasBirth = place.people.some(p => p.type === "birth")
          const hasDeath = place.people.some(p => p.type === "death")

          const color = hasBirth && hasDeath ? "#a78bfa" : hasBirth ? "#34d399" : "#f87171"

          const icon = L.divIcon({
            className: "map-marker-custom",
            html: `<div style="
              width: 14px; height: 14px;
              background: ${color};
              border: 2px solid rgba(255,255,255,0.6);
              border-radius: 50%;
              box-shadow: 0 0 10px ${color}80;
            "></div>`,
            iconSize: [14, 14],
            iconAnchor: [7, 7]
          })

          const popupContent = this.buildPopup(place)

          const marker = L.marker([coords.lat, coords.lng], { icon })
            .addTo(this.map)
            .bindPopup(popupContent, {
              className: "map-popup-dark",
              maxWidth: 250
            })

          this.markers.push(marker)
        }

        this.geocodeAndPlot(places, index + 1)
      })
    }, index === 0 ? 0 : 1100)
  }

  async geocode(place) {
    const key = place.toLowerCase().trim()
    if (this.geocodeCache[key]) return this.geocodeCache[key]

    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(place)}&limit=1`,
        { headers: { "User-Agent": "FamilyTreeBuilder/1.0" } }
      )
      const results = await response.json()
      if (results.length > 0) {
        const coords = { lat: parseFloat(results[0].lat), lng: parseFloat(results[0].lon) }
        this.geocodeCache[key] = coords
        return coords
      }
    } catch (err) {
      console.warn("Geocoding failed for:", place, err)
    }

    return null
  }

  buildPopup(place) {
    let html = `<div style="font-family:Inter,sans-serif;">
      <strong style="font-size:13px;">${place.place}</strong><br>`

    place.people.forEach(p => {
      const icon = p.type === "birth" ? "👶" : "🕊️"
      const year = p.year ? ` (${p.year})` : ""
      html += `<div style="font-size:11px; margin-top:4px;">
        ${icon} <a href="/people/${p.id}" style="color:#818cf8;">${p.name}</a>${year}
      </div>`
    })

    html += "</div>"
    return html
  }
}
