import "./main.css";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";
import * as d3 from "d3";

//elm st
const app = Elm.Main.init({
  node: document.getElementById("root")
});

//ports
app.ports.cache.subscribe(function(data) {
  localStorage.setItem("cache", JSON.stringify(data));
  console.log(data);
});

//ELM -> JS Port
app.ports.sendWS.subscribe(function(data) {
  localStorage.setItem("cache", JSON.stringify(data));
  websocket.send(JSON.stringify(data));
  console.log("/////////////////////////////////");
  console.log("WS SENT ");
  console.log(data);
});

// load event
window.addEventListener("load", event => {
  const windowSize = {
    height: event.currentTarget.innerHeight,
    width: event.currentTarget.innerWidth
  };
  app.ports.window.send(windowSize);
});

//resize event
window.addEventListener("resize", event => {
  const windowSize = {
    height: event.target.innerHeight,
    width: event.target.innerWidth
  };
  app.ports.window.send(windowSize);
  // console.log('resize event')
});

// Create WebSocket connection.
const websocket = new WebSocket("wss://www.deribit.com/ws/api/v1/");

//register event handlers below
websocket.onopen = function(evt) {
  onOpen(evt);
};
websocket.onclose = function(evt) {
  onClose(evt);
};
websocket.onmessage = function(evt) {
  onMessage(evt);
};
websocket.onerror = function(evt) {
  onError(evt);
};

//Websocket Event Handlers
const onOpen = evt => {
  console.log("Websocket | Open event");
  //when the websocket is ready, fire the message to be echoed
  const message = {
    action: "/api/v1/public/getinstruments",
    arguments: { expired: false }
  }; //send an object
  // have to stringify it when sending
  websocket.send(JSON.stringify(message));
};

const onClose = evt => {
  console.log("Websocket | Close event");
};

const onMessage = evt => {
  // parse the stringified message
  const data = JSON.parse(evt.data);
  console.log("/////////////////////////////////");
  console.log("WS RECEIVED");
  console.log(data);

  //send the data back to elm
  // app.ports.receiveWS.send(data);
};

const onError = evt => {
  console.log("Websocket | Error event", evt);
};

// generate access key code

let access_key = "2YZn85siaUf5A";
let secret_key = "BTMSIAJ8IYQTAV4MLN88UAHLIUNYZ3HN";

function get_signature(action, args) {
  let nonce = new Date().getTime().toString();

  let signatureString =
    "_=" +
    nonce +
    "&_ackey=" +
    access_key +
    "&_acsec=" +
    secret_key +
    "&_action=" +
    action;

  Object.keys(args)
    .sort()
    .forEach(key => {
      signatureString += "&";
      signatureString += key;
      signatureString += "=";

      let value = args[key];
      if (Array.isArray(value)) {
        value = value.join("");
      }

      signatureString += value.toString();
    });
  let signatureStringEncoded = new TextEncoder("utf-8").encode(signatureString);
  let binaryHash = crypto.subtle.digest("SHA-256", signatureStringEncoded);
  return access_key + "." + nonce.toString() + "." + btoa(binaryHash);
}

// register service worker (comes with create-elm-app)
registerServiceWorker();


/////////////////////////////////////////////////////////////////////////////////////////////////
//d3
const data = [12, 24, 50, 200, 100]
const rectWidth = 50

d3.selectAll('rect')
  .data(data)
  .attr('x', (d, i) => i * rectWidth)
  .attr('y', d => 199 - d)
  .attr('width', rectWidth)
  .attr('height', d => d)
  .attr('fill', 'blue')
  .attr('stroke', 'red')

