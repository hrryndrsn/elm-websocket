import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const app = Elm.Main.init({
  node: document.getElementById('root')
});

app.ports.cache.subscribe(function(data) {
  localStorage.setItem('cache', JSON.stringify(data));
  console.log(data)
});



window.addEventListener('load', (event) => {
  const windowSize = { 
    height: event.currentTarget.innerHeight,
    width: event.currentTarget.innerWidth
    }
  app.ports.window.send(windowSize);
  console.log('load event', event.currentTarget.innerHeight, event.currentTarget.innerWidth)
});

window.addEventListener('resize', (event) => {
  const windowSize = { 
    height: event.target.innerHeight,
    width: event.target.innerWidth
    }
  app.ports.window.send(windowSize);
  console.log('resize event')
});

registerServiceWorker();
