import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  static values = { url: String, linkUrl: String }

  connect() {
    this.sidebar = document.getElementById("quick-view-sidebar")
    this.sidebarContent = document.getElementById("quick-view-content")
    
    document.getElementById("close-quick-view").addEventListener("click", () => {
      this.sidebar.style.display = "none"
    })

    fetch(this.urlValue)
      .then(r => r.json())
      .then(data => {
        this.treeData = data
        this.renderTree()
      })
      .catch(err => {
        this.element.innerHTML = '<div class="empty-state"><p>Failed to load tree data.</p></div>'
        console.error("Tree load error:", err)
      })
  }

  renderTree() {
    const container = this.element
    const width = container.clientWidth
    const height = container.clientHeight || 600

    container.innerHTML = ""

    const svg = d3.select(container)
      .append("svg")
      .attr("width", "100%")
      .attr("height", "100%")
      .attr("viewBox", `0 0 ${width} ${height}`)
      .style("background", "transparent")
      .style("cursor", "grab")

    // The main group for panning and zooming
    this.gMain = svg.append("g")

    // Setup Zoom
    const zoom = d3.zoom()
      .scaleExtent([0.1, 3])
      .on("zoom", (event) => {
        this.gMain.attr("transform", event.transform)
      })
    svg.call(zoom)

    // Layout calculation
    this.updateGraph(width, height)
  }

  updateGraph(width, height) {
    const layout = this.computeLayout(this.treeData, width, height)
    
    // Draw Links
    const link = this.gMain.selectAll(".link")
      .data(layout.connections, d => d.id)

    link.enter()
      .append("line")
      .attr("class", "link")
      .attr("stroke", "rgba(99, 102, 241, 0.4)")
      .attr("stroke-width", 2)
      .attr("x1", d => d.x1)
      .attr("y1", d => d.y1)
      .attr("x2", d => d.x2)
      .attr("y2", d => d.y2)

    // Draw Nodes
    const node = this.gMain.selectAll(".node")
      .data(layout.nodes, d => d.id)

    const nodeEnter = node.enter()
      .append("g")
      .attr("class", "node")
      .attr("transform", d => `translate(${d.x},${d.y})`)
      .style("cursor", "pointer")
      .on("click", (event, d) => {
        if (event.defaultPrevented) return // ignore drag
        this.showQuickView(d)
      })

    // Drag behavior
    const drag = d3.drag()
      .on("start", (event, d) => {
        d3.select(event.sourceEvent.target.parentNode).raise().classed("active", true)
      })
      .on("drag", (event, d) => {
        d.x += event.dx
        d.y += event.dy
        d3.select(event.sourceEvent.target.parentNode).attr("transform", `translate(${d.x},${d.y})`)
      })
      .on("end", (event, d) => {
        d3.select(event.sourceEvent.target.parentNode).classed("active", false)
        this.handleDrop(d, event.sourceEvent.clientX, event.sourceEvent.clientY)
        // Redraw to reset position if not valid drop
        this.updateGraph(this.element.clientWidth, this.element.clientHeight || 600)
      })

    nodeEnter.call(drag)

    // Node Cards
    nodeEnter.append("rect")
      .attr("x", -85)
      .attr("y", -35)
      .attr("width", 170)
      .attr("height", 70)
      .attr("rx", 12)
      .attr("fill", d => d.isRoot ? "rgba(99, 102, 241, 0.15)" : "var(--bg-card)")
      .attr("stroke", d => this.genderColor(d.gender, 0.8))
      .attr("stroke-width", d => d.isRoot ? 3 : 1)
      .style("filter", "drop-shadow(0 4px 6px rgba(0,0,0,0.3))")

    // Names
    nodeEnter.append("text")
      .attr("text-anchor", "middle")
      .attr("y", -5)
      .attr("fill", "var(--text-primary)")
      .style("font-size", "14px")
      .style("font-weight", "600")
      .style("font-family", "Inter")
      .style("pointer-events", "none")
      .text(d => this.truncate(d.name, 18))

    // Dates
    nodeEnter.append("text")
      .attr("text-anchor", "middle")
      .attr("y", 15)
      .attr("fill", "var(--text-muted)")
      .style("font-size", "11px")
      .style("font-family", "Inter")
      .style("pointer-events", "none")
      .text(d => {
        const by = d.birth_year || "?"
        const dy = d.death_year ? ` – ${d.death_year}` : ""
        return `${by}${dy}`
      })

    // Sub-label (Relationship)
    nodeEnter.append("text")
      .attr("text-anchor", "middle")
      .attr("y", 28)
      .attr("fill", "var(--accent-light)")
      .style("font-size", "10px")
      .style("font-family", "Inter")
      .style("pointer-events", "none")
      .text(d => d.role || "")

    node.attr("transform", d => `translate(${d.x},${d.y})`)
    
    // Merge & update lines
    this.gMain.selectAll(".link")
      .attr("x1", d => d.x1)
      .attr("y1", d => d.y1)
      .attr("x2", d => d.x2)
      .attr("y2", d => d.y2)
  }

  showQuickView(node) {
    this.sidebar.style.display = "flex"
    const dates = node.birth_year ? `${node.birth_year} - ${node.death_year || 'Present'}` : "Dates Unknown"
    
    this.sidebarContent.innerHTML = `
      <div style="display: flex; flex-direction: column; align-items: center; gap: 1rem; padding: 0 1rem;">
        <div style="width: 80px; height: 80px; border-radius: 50%; background: ${this.genderColor(node.gender, 0.2)}; border: 2px solid ${this.genderColor(node.gender, 1)}; display: flex; align-items: center; justify-content: center; font-size: 2rem; color: var(--text-primary);">
          ${node.name.charAt(0)}
        </div>
        <div style="text-align: center;">
          <h3 style="margin: 0; font-size: 1.2rem;">${node.name}</h3>
          <p style="color: var(--text-muted); margin: 0.2rem 0; font-size: 0.9rem;">${dates}</p>
        </div>
        
        <div style="width: 100%; border-top: 1px solid var(--border-glass); margin-top: 1rem; padding-top: 1rem;">
          <a href="/people/${node.id}" class="btn btn-primary" style="width: 100%; text-align: center; margin-bottom: 0.5rem;" data-turbo="false">View Full Profile</a>
          <a href="/people/${node.id}/edit" class="btn btn-secondary" style="width: 100%; text-align: center;">Edit Details</a>
        </div>
      </div>
    `
  }

  handleDrop(draggedNode, mouseX, mouseY) {
    // Check if mouse is over another node
    const svgRect = this.element.querySelector("svg").getBoundingClientRect()
    const transform = d3.zoomTransform(this.element.querySelector("svg"))
    
    // Convert mouse coordinates to SVG coordinates
    const svgX = (mouseX - svgRect.left - transform.x) / transform.k
    const svgY = (mouseY - svgRect.top - transform.y) / transform.k

    // Find dropped target
    let targetNode = null
    const nodes = this.computeLayout(this.treeData, this.element.clientWidth, this.element.clientHeight || 600).nodes
    
    for (const n of nodes) {
      if (n.id === draggedNode.id) continue
      // Hitbox logic (rect is 170x70, centered)
      if (svgX > n.x - 85 && svgX < n.x + 85 && svgY > n.y - 35 && svgY < n.y + 35) {
        targetNode = n
        break
      }
    }

    if (targetNode) {
      const relation = prompt(`How is ${draggedNode.name} related to ${targetNode.name}?\nType: parent, child, or spouse`)
      if (['parent', 'child', 'spouse'].includes(relation)) {
        this.linkNodes(draggedNode.id, targetNode.id, relation)
      } else if (relation) {
        alert("Invalid relationship type.")
      }
    }
  }

  linkNodes(sourceId, targetId, relationType) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    fetch(this.linkUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ source_id: sourceId, target_id: targetId, relation_type: relationType })
    })
    .then(r => r.json())
    .then(data => {
      if (data.success) {
        // Reload tree
        this.connect()
      } else {
        alert("Error linking nodes: " + data.error)
      }
    })
  }

  // --- Layout Engine ---
  computeLayout(data, width, height) {
    const nodes = []
    const connections = []
    let linkId = 0
    const centerX = width / 2
    const rootY = height / 2

    // Root node
    nodes.push({ ...data, x: centerX, y: rootY, isRoot: true, role: "Focus" })

    // Spouses next to root
    if (data.spouses) {
      data.spouses.forEach((spouse, i) => {
        const sx = centerX + 190 * (i + 1)
        nodes.push({ ...spouse, x: sx, y: rootY, isRoot: false, role: "Spouse" })
        connections.push({ id: `l_${linkId++}`, x1: centerX + 85, y1: rootY, x2: sx - 85, y2: rootY })
      })
    }

    // Parents above
    if (data.parents) {
      const parentCount = data.parents.length
      const parentSpacing = 220
      const parentStartX = centerX - ((parentCount - 1) * parentSpacing) / 2
      const parentY = rootY - 140

      data.parents.forEach((parent, i) => {
        const px = parentStartX + i * parentSpacing
        nodes.push({ ...parent, x: px, y: parentY, isRoot: false, role: "Parent" })
        connections.push({ id: `l_${linkId++}`, x1: centerX, y1: rootY - 35, x2: px, y2: parentY + 35 })

        // Grandparents
        if (parent.parents) {
          const gpCount = parent.parents.length
          const gpSpacing = 180
          const gpStartX = px - ((gpCount - 1) * gpSpacing) / 2
          const gpY = parentY - 140

          parent.parents.forEach((gp, j) => {
            const gpx = gpStartX + j * gpSpacing
            nodes.push({ ...gp, x: gpx, y: gpY, isRoot: false, role: "Grandparent" })
            connections.push({ id: `l_${linkId++}`, x1: px, y1: parentY - 35, x2: gpx, y2: gpY + 35 })
          })
        }
      })
    }

    // Children below
    if (data.children) {
      const childCount = data.children.length
      const childSpacing = 200
      const childStartX = centerX - ((childCount - 1) * childSpacing) / 2
      const childY = rootY + 140

      data.children.forEach((child, i) => {
        const cx = childStartX + i * childSpacing
        nodes.push({ ...child, x: cx, y: childY, isRoot: false, role: "Child" })
        connections.push({ id: `l_${linkId++}`, x1: centerX, y1: rootY + 35, x2: cx, y2: childY - 35 })
      })
    }

    return { nodes, connections }
  }

  genderColor(gender, alpha) {
    switch (gender) {
      case "male": return `rgba(96, 165, 250, ${alpha})`
      case "female": return `rgba(244, 114, 182, ${alpha})`
      default: return `rgba(167, 139, 250, ${alpha})`
    }
  }

  truncate(str, len) {
    if (!str) return ""
    return str.length > len ? str.slice(0, len - 1) + "…" : str
  }
}
