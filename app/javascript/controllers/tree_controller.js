import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    fetch(this.urlValue)
      .then(r => r.json())
      .then(data => this.renderTree(data))
      .catch(err => {
        this.element.innerHTML = '<div class="empty-state"><p>Failed to load tree data.</p></div>'
        console.error("Tree load error:", err)
      })
  }

  renderTree(data) {
    const container = this.element
    const width = container.clientWidth
    const height = container.clientHeight || 600

    // Collect all nodes into a flat list for layout
    const nodes = []
    this.flattenTree(data, nodes, 0, null)

    // Create SVG
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("width", "100%")
    svg.setAttribute("height", "100%")
    svg.setAttribute("viewBox", `0 0 ${width} ${height}`)
    svg.style.background = "transparent"
    
    // Viewport group for panning/zooming
    const viewport = document.createElementNS("http://www.w3.org/2000/svg", "g")
    svg.appendChild(viewport)
    
    container.innerHTML = ""
    container.appendChild(svg)

    // Layout: center the root, parents above, children below
    const levels = this.computeLayout(data, width, height)

    // Draw connections
    levels.connections.forEach(conn => {
      const line = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line.setAttribute("x1", conn.x1)
      line.setAttribute("y1", conn.y1)
      line.setAttribute("x2", conn.x2)
      line.setAttribute("y2", conn.y2)
      line.setAttribute("stroke", "rgba(99, 102, 241, 0.3)")
      line.setAttribute("stroke-width", "2")
      viewport.appendChild(line)
    })

    // Draw nodes
    levels.nodes.forEach(node => {
      const g = document.createElementNS("http://www.w3.org/2000/svg", "g")
      g.setAttribute("transform", `translate(${node.x}, ${node.y})`)
      g.style.cursor = "pointer"

      // Card background
      const rect = document.createElementNS("http://www.w3.org/2000/svg", "rect")
      rect.setAttribute("x", -75)
      rect.setAttribute("y", -30)
      rect.setAttribute("width", 150)
      rect.setAttribute("height", 60)
      rect.setAttribute("rx", 10)
      rect.setAttribute("fill", node.isRoot ? "rgba(99, 102, 241, 0.2)" : "rgba(30, 30, 50, 0.9)")
      rect.setAttribute("stroke", this.genderColor(node.gender, 0.4))
      rect.setAttribute("stroke-width", node.isRoot ? "2" : "1")
      g.appendChild(rect)

      // Name text
      const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
      text.setAttribute("text-anchor", "middle")
      text.setAttribute("y", -5)
      text.setAttribute("fill", "#e8e8f0")
      text.setAttribute("font-size", "12")
      text.setAttribute("font-weight", "600")
      text.setAttribute("font-family", "Inter, sans-serif")
      text.textContent = this.truncate(node.name, 18)
      // Make text non-selectable during drag
      text.style.userSelect = "none"
      g.appendChild(text)

      // Dates
      const dates = document.createElementNS("http://www.w3.org/2000/svg", "text")
      dates.setAttribute("text-anchor", "middle")
      dates.setAttribute("y", 15)
      dates.setAttribute("fill", "#6b7280")
      dates.setAttribute("font-size", "10")
      dates.setAttribute("font-family", "Inter, sans-serif")
      dates.style.userSelect = "none"
      const birthYear = node.birth_year || "?"
      const deathYear = node.death_year ? ` – ${node.death_year}` : ""
      dates.textContent = `${birthYear}${deathYear}`
      g.appendChild(dates)

      // Click to navigate (ignore if panning)
      let clickStart = { x: 0, y: 0 }
      g.addEventListener("mousedown", (e) => {
        clickStart = { x: e.clientX, y: e.clientY }
      })
      g.addEventListener("click", (e) => {
        const dx = Math.abs(e.clientX - clickStart.x)
        const dy = Math.abs(e.clientY - clickStart.y)
        if (dx < 5 && dy < 5) {
          window.location.href = `/people/${node.id}`
        }
      })

      // Hover effect
      g.addEventListener("mouseenter", () => {
        rect.setAttribute("stroke", this.genderColor(node.gender, 0.8))
        rect.setAttribute("stroke-width", "2")
      })
      g.addEventListener("mouseleave", () => {
        rect.setAttribute("stroke", this.genderColor(node.gender, 0.4))
        rect.setAttribute("stroke-width", node.isRoot ? "2" : "1")
      })

      viewport.appendChild(g)
    })
    
    // Initialize Pan and Zoom interactions
    this.setupPanZoom(svg, viewport)
  }

  setupPanZoom(svg, viewport) {
    let isPanning = false
    let startPoint = { x: 0, y: 0 }
    let currentPan = { x: 0, y: 0 }
    let scale = 1

    svg.style.cursor = "grab"

    const updateTransform = () => {
      viewport.setAttribute("transform", `translate(${currentPan.x}, ${currentPan.y}) scale(${scale})`)
    }

    svg.addEventListener("mousedown", (e) => {
      if (e.target.tagName !== "svg" && e.target.tagName !== "line" && e.target.tagName !== "rect") return
      isPanning = true
      startPoint = { x: e.clientX - currentPan.x, y: e.clientY - currentPan.y }
      svg.style.cursor = "grabbing"
    })

    window.addEventListener("mousemove", (e) => {
      if (!isPanning) return
      e.preventDefault()
      currentPan = { x: e.clientX - startPoint.x, y: e.clientY - startPoint.y }
      updateTransform()
    })

    window.addEventListener("mouseup", () => {
      isPanning = false
      svg.style.cursor = "grab"
    })

    svg.addEventListener("wheel", (e) => {
      e.preventDefault()
      // Wheel delta varies by OS/Browser, normalize slightly
      const zoomFactor = -e.deltaY * 0.001
      const newScale = Math.min(Math.max(0.2, scale + zoomFactor), 3)
      
      const rect = svg.getBoundingClientRect()
      const mouseX = e.clientX - rect.left
      const mouseY = e.clientY - rect.top

      // Zoom toward cursor math
      currentPan.x = mouseX - (mouseX - currentPan.x) * (newScale / scale)
      currentPan.y = mouseY - (mouseY - currentPan.y) * (newScale / scale)
      scale = newScale
      
      updateTransform()
    }, { passive: false })
  }

  computeLayout(data, width, height) {
    const nodes = []
    const connections = []
    const centerX = width / 2
    const rootY = height / 2

    // Root node
    nodes.push({ ...data, x: centerX, y: rootY, isRoot: true })

    // Spouses next to root
    if (data.spouses) {
      data.spouses.forEach((spouse, i) => {
        const sx = centerX + 180 * (i + 1)
        nodes.push({ ...spouse, x: sx, y: rootY, isRoot: false })
        connections.push({ x1: centerX + 75, y1: rootY, x2: sx - 75, y2: rootY })
      })
    }

    // Parents above
    if (data.parents) {
      const parentCount = data.parents.length
      const parentSpacing = 200
      const parentStartX = centerX - ((parentCount - 1) * parentSpacing) / 2
      const parentY = rootY - 120

      data.parents.forEach((parent, i) => {
        const px = parentStartX + i * parentSpacing
        nodes.push({ ...parent, x: px, y: parentY, isRoot: false })
        connections.push({ x1: centerX, y1: rootY - 30, x2: px, y2: parentY + 30 })

        // Grandparents
        if (parent.parents) {
          const gpCount = parent.parents.length
          const gpSpacing = 160
          const gpStartX = px - ((gpCount - 1) * gpSpacing) / 2
          const gpY = parentY - 110

          parent.parents.forEach((gp, j) => {
            const gpx = gpStartX + j * gpSpacing
            nodes.push({ ...gp, x: gpx, y: gpY, isRoot: false })
            connections.push({ x1: px, y1: parentY - 30, x2: gpx, y2: gpY + 30 })
          })
        }
      })
    }

    // Children below
    if (data.children) {
      const childCount = data.children.length
      const childSpacing = 180
      const childStartX = centerX - ((childCount - 1) * childSpacing) / 2
      const childY = rootY + 120

      data.children.forEach((child, i) => {
        const cx = childStartX + i * childSpacing
        nodes.push({ ...child, x: cx, y: childY, isRoot: false })
        connections.push({ x1: centerX, y1: rootY + 30, x2: cx, y2: childY - 30 })

        // Grandchildren
        if (child.children) {
          const gcCount = child.children.length
          const gcSpacing = 150
          const gcStartX = cx - ((gcCount - 1) * gcSpacing) / 2
          const gcY = childY + 110

          child.children.forEach((gc, j) => {
            const gcx = gcStartX + j * gcSpacing
            nodes.push({ ...gc, x: gcx, y: gcY, isRoot: false })
            connections.push({ x1: cx, y1: childY + 30, x2: gcx, y2: gcY - 30 })
          })
        }
      })
    }

    return { nodes, connections }
  }

  flattenTree(node, list, depth, parentId) {
    if (!node) return
    list.push({ ...node, depth, parentId })
    if (node.parents) node.parents.forEach(p => this.flattenTree(p, list, depth - 1, node.id))
    if (node.children) node.children.forEach(c => this.flattenTree(c, list, depth + 1, node.id))
  }

  genderColor(gender, alpha) {
    switch (gender) {
      case "male": return `rgba(96, 165, 250, ${alpha})`
      case "female": return `rgba(244, 114, 182, ${alpha})`
      default: return `rgba(167, 139, 250, ${alpha})`
    }
  }

  truncate(str, len) {
    return str.length > len ? str.slice(0, len - 1) + "…" : str
  }
}
