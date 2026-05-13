import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["input"]

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query.length < 2) {
        document.getElementById("search_results").innerHTML = ""
        return
      }

      fetch(`/search?q=${encodeURIComponent(query)}`, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
        .then(response => response.text())
        .then(html => Turbo.renderStreamMessage(html))
    }, 300)
  }
}
