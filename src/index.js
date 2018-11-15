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

registerServiceWorker();
