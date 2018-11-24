import "./main.css";
import { Elm } from "./Main.elm";
import registerServiceWorker from "./registerServiceWorker";
import * as d3 from "d3";
import * as fetch from 'd3-fetch';
// import tempData from "./tempData.tsv"

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
const websocket = new WebSocket("wss://ws-feed.pro.coinbase.com");

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
  const sub = {
    "type": "subscribe",
    "product_ids": [
        "ETH-EUR"
    ],
    "channels": [
        "level2",
        "heartbeat",
        {
            "name": "ticker",
            "product_ids": [
                "ETH-BTC",
                "ETH-USD"
            ]
        }
    ]
  }; 
  const unsub = {
    "type": "unsubscribe",
    "product_ids": [
        "ETH-USD"
    ],
    "channels": [
        "level2",
        "heartbeat",
        {
            "name": "ticker",
            "product_ids": [
                "ETH-BTC",
                "ETH-USD"
            ]
        }
    ]
  }; 
  //send an object
  // have to stringify it when sending
  websocket.send(JSON.stringify(sub));
  setTimeout(() => websocket.send(JSON.stringify(unsub)), 2000)
};

const onClose = evt => {
  console.log("Websocket | Close event");
};

const onMessage = evt => {
  // parse the stringified message
  const data = JSON.parse(evt.data);
  switch(data.type) {
    case "snapshot":
      console.log("snapshot ///");
      app.ports.receiveWS.send(data.type)
    case "l2update":
      console.log("L2 Update ///");
  }

  console.log("/////////////////////////////////");
  console.log("WS RECEIVED");
  console.log(data);

  //send the data back to elm
  // app.ports.receiveWS.send(data);
};

const onError = evt => {
  console.log("Websocket | Error event", evt);
};


// register service worker (comes with create-elm-app)
registerServiceWorker();



