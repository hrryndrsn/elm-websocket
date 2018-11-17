import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

//elm st
const app = Elm.Main.init({
  node: document.getElementById('root')
});

app.ports.cache.subscribe(function(data) {
  localStorage.setItem('cache', JSON.stringify(data));
  console.log(data)
});


// load event
window.addEventListener('load', (event) => {
  const windowSize = { 
    height: event.currentTarget.innerHeight,
    width: event.currentTarget.innerWidth
    }
    app.ports.window.send(windowSize);
    
});

//resize event
window.addEventListener('resize', (event) => {
  const windowSize = { 
    height: event.target.innerHeight,
    width: event.target.innerWidth
    }
  app.ports.window.send(windowSize);
  console.log('resize event')
});




// Create WebSocket connection.
const websocket = new WebSocket('wss://echo.websocket.org/');

websocket.onopen = function(evt) { onOpen(evt) };
websocket.onclose = function(evt) { onClose(evt) };
websocket.onmessage = function(evt) { onMessage(evt) };
websocket.onerror = function(evt) { onError(evt) };



//Websocket Handlers
const onOpen = (evt) => {
  console.log("Websocket | Open event");
  //when the websocket is ready, fire the message to be echoed
  websocket.send("echo");
};

const onClose = (evt) => {
  console.log("Websocket | Close event");
};

const onMessage = (evt) => {
  console.log(`Websocket | Message Recieved`, evt);
};

const onError = (evt) => {
  console.log("Websocket | Error event", evt);
};





// register service worker (comes with create-elm-app)
registerServiceWorker();
