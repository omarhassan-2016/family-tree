import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    fetch(this.urlValue)
      .then(r => r.json())
      .then(arcs => this.render(arcs))
      .catch(err => {
        this.element.innerHTML = '<div class="empty-state"><p>Failed to load fan chart data.</p></div>'
        console.error("Fan chart error:", err)
      })
  }

  render(arcs) {
    const container = this.element
    const size = Math.min(container.clientWidth, container.clientHeight || 650)
    const cx = size / 2
    const cy = size / 2
    const innerRadius = 50
    const ringWidth = (size / 2 - innerRadius - 20) / 5

    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("width", "100%")
    svg.setAttribute("height", "100%")
    svg.setAttribute("viewBox", `0 0 ${size} ${size}`)
    svg.style.background = "transparent"
    container.innerHTML = ""
    container.appendChild(svg)

    // Generation ring colors with increasing opacity
    const genColors = [
      "rgba(99, 102, 241, 0.25)",
      "rgba(99, 102, 241, 0.15)",
      "rgba(99, 102, 241, 0.10)",
      "rgba(99, 102, 241, 0.08)",
      "rgba(99, 102, 241, 0.05)"
    ]

    arcs.forEach(arc => {
      if (arc.generation === 0) {
        // Center circle for root person
        const g = document.createElementNS("http://www.w3.org/2000/svg", "g")
        g.style.cursor = "pointer"

        const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")
        circle.setAttribute("cx", cx)
        circle.setAttribute("cy", cy)
        circle.setAttribute("r", innerRadius)
        circle.setAttribute("fill", "rgba(99, 102, 241, 0.3)")
        circle.setAttribute("stroke", "rgba(99, 102, 241, 0.5)")
        circle.setAttribute("stroke-width", "2")
        g.appendChild(circle)

        if (arc.person) {
          const text = this.createText(cx, cy - 6, arc.person.name, 11, "#e8e8f0", "600")
          g.appendChild(text)
          const dates = this.createText(cx, cy + 12, this.formatDates(arc.person), 9, "#9ca3af", "400")
          g.appendChild(dates)

          g.addEventListener("click", () => window.location.href = `/people/${arc.person.id}`)
        }
        svg.appendChild(g)
        return
      }

      const r1 = innerRadius + (arc.generation - 1) * ringWidth
      const r2 = innerRadius + arc.generation * ringWidth
      const a1 = (arc.start_angle - 90) * Math.PI / 180
      const a2 = (arc.end_angle - 90) * Math.PI / 180

      const g = document.createElementNS("http://www.w3.org/2000/svg", "g")

      // Arc path
      const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
      const x1o = cx + r2 * Math.cos(a1)
      const y1o = cy + r2 * Math.sin(a1)
      const x2o = cx + r2 * Math.cos(a2)
      const y2o = cy + r2 * Math.sin(a2)
      const x1i = cx + r1 * Math.cos(a2)
      const y1i = cy + r1 * Math.sin(a2)
      const x2i = cx + r1 * Math.cos(a1)
      const y2i = cy + r1 * Math.sin(a1)

      const largeArc = (arc.end_angle - arc.start_angle) > 180 ? 1 : 0

      const d = [
        `M ${x1o} ${y1o}`,
        `A ${r2} ${r2} 0 ${largeArc} 1 ${x2o} ${y2o}`,
        `L ${x1i} ${y1i}`,
        `A ${r1} ${r1} 0 ${largeArc} 0 ${x2i} ${y2i}`,
        `Z`
      ].join(" ")

      let fillColor = genColors[Math.min(arc.generation - 1, genColors.length - 1)]
      let strokeColor = "rgba(255,255,255,0.06)"

      if (arc.person) {
        fillColor = arc.person.gender === "male"
          ? `rgba(96, 165, 250, ${0.25 - arc.generation * 0.03})`
          : arc.person.gender === "female"
            ? `rgba(244, 114, 182, ${0.25 - arc.generation * 0.03})`
            : fillColor
        strokeColor = arc.person.gender === "male"
          ? "rgba(96, 165, 250, 0.3)"
          : arc.person.gender === "female"
            ? "rgba(244, 114, 182, 0.3)"
            : strokeColor
      }

      path.setAttribute("d", d)
      path.setAttribute("fill", fillColor)
      path.setAttribute("stroke", strokeColor)
      path.setAttribute("stroke-width", "1")
      g.appendChild(path)

      // Text label (only if arc is wide enough)
      if (arc.person) {
        const midAngle = ((arc.start_angle + arc.end_angle) / 2 - 90) * Math.PI / 180
        const midR = (r1 + r2) / 2
        const tx = cx + midR * Math.cos(midAngle)
        const ty = cy + midR * Math.sin(midAngle)

        const arcSpan = arc.end_angle - arc.start_angle
        const fontSize = arcSpan > 40 ? 9 : arcSpan > 20 ? 7 : 0

        if (fontSize > 0) {
          const name = this.truncate(arc.person.name, arcSpan > 40 ? 16 : 10)
          const text = this.createText(tx, ty - 2, name, fontSize, "#e8e8f0", "500")

          // Rotate text to follow arc
          const rotDeg = (arc.start_angle + arc.end_angle) / 2
          const flip = rotDeg > 90 && rotDeg < 270
          const textRot = flip ? rotDeg + 180 : rotDeg
          text.setAttribute("transform", `rotate(${textRot}, ${tx}, ${ty})`)
          g.appendChild(text)

          if (arcSpan > 30) {
            const dates = this.createText(tx, ty + 10, this.formatDates(arc.person), Math.max(fontSize - 2, 6), "#6b7280", "400")
            dates.setAttribute("transform", `rotate(${textRot}, ${tx}, ${ty + 10})`)
            g.appendChild(dates)
          }
        }

        g.style.cursor = "pointer"
        g.addEventListener("click", () => window.location.href = `/people/${arc.person.id}`)
        g.addEventListener("mouseenter", () => {
          path.setAttribute("fill", arc.person.gender === "male" ? "rgba(96,165,250,0.4)" : arc.person.gender === "female" ? "rgba(244,114,182,0.4)" : "rgba(99,102,241,0.4)")
        })
        g.addEventListener("mouseleave", () => path.setAttribute("fill", fillColor))
      }

      svg.appendChild(g)
    })
  }

  createText(x, y, content, size, fill, weight) {
    const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
    text.setAttribute("x", x)
    text.setAttribute("y", y)
    text.setAttribute("text-anchor", "middle")
    text.setAttribute("dominant-baseline", "middle")
    text.setAttribute("fill", fill)
    text.setAttribute("font-size", size)
    text.setAttribute("font-weight", weight)
    text.setAttribute("font-family", "Inter, sans-serif")
    text.textContent = content
    return text
  }

  formatDates(person) {
    const b = person.birth_year || "?"
    const d = person.death_year ? ` – ${person.death_year}` : ""
    return `${b}${d}`
  }

  truncate(str, len) {
    return str.length > len ? str.slice(0, len - 1) + "…" : str
  }
}
