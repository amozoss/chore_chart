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
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// Sound effect support
let Hooks = {};

Hooks.Sound = {
  mounted() {
    this.audioContext = new (window.AudioContext ||
      window.webkitAudioContext)();
    this.gainNode = this.audioContext.createGain();
    this.gainNode.connect(this.audioContext.destination);
    this.gainNode.gain.value = 0.4;
    this.buffers = {};

    // Load all sound effects
    const sounds = [
      "1-up",
      "bowserfalls",
      "bowserfire",
      "breakblock",
      "bump",
      "coin",
      "fireball",
      "fireworks",
      "flagpole",
      "gameover",
      "jump-small",
      "jump-super",
      "kick",
      "mariodie",
      "pause",
      "pipe",
      "powerup",
      "powerup_appears",
      "stage_clear",
      "stomp",
      "underworld",
      "vine",
      "warning",
      "world_clear",
    ];

    sounds.forEach((sound) => this.loadSound(sound));

    this.handleEvent("play_sound", ({ sound }) => {
      this.playSound(sound);
    });
  },

  loadSound(key) {
    fetch(`/audio/${key}.wav`)
      .then((response) => response.arrayBuffer())
      .then((data) => this.audioContext.decodeAudioData(data))
      .then((buffer) => {
        this.buffers[key] = buffer;
      })
      .catch((error) => console.error(`Error loading sound ${key}:`, error));
  },

  playSound(key) {
    const buffer = this.buffers[key];
    if (!buffer) return;

    const source = this.audioContext.createBufferSource();
    source.buffer = buffer;
    source.connect(this.gainNode);
    source.start(0);
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
