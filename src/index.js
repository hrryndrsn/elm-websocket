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

window.addEventListener('resize', (event) => {
  console.log(event)
  const activeUsers = { 
    height: event.target.innerHeight,
    width: event.target.innerWidth
    }
  app.ports.window.send(activeUsers);
  console.log('resize event')
})

registerServiceWorker();
