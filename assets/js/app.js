// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

function clamp(min, max, val) {
  return Math.max(min, Math.min(max, val))
}

function lerp(v0, v1, t) {
  return v0 + t * (v1 - v0)
}

function elemToPos(elem) {
  const {cx, cy} = elem.dataset
  return {cx: parseFloat(cx), cy: parseFloat(cy)}
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

function init() {
  const elem = this.el
  const {cx, cy} = elemToPos(elem)
  this.cx = cx
  this.cy = cy
  this.previousTime = performance.now()
}

function update(deltaTime) {
  const elem = this.el
  const { cx, cy } = elemToPos(elem)

  this.cx = lerp(this.cx, cx, 0.5)
  this.cy = lerp(this.cy, cy, 0.5)
  elem.setAttribute("cx", this.cx)
  elem.setAttribute("cy", this.cy)
}

function animate() {
  const currentTime = performance.now()
  const deltaTime = currentTime - this.previousTime
  this.previousTime = currentTime

  update.call(this, deltaTime)

  requestAnimationFrame(animate.bind(this))
}

let Hooks = {}
Hooks.Animate = {
  cx: null,
  cy: null,
  mounted() {
    init.call(this)
    animate.call(this)
  }
}
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
liveSocket.disableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
