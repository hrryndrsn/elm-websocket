## Elm websocket fun

Ported create-elm-app

each changes array changes, each chnage is an tri tuple array

changes [ change ]

change =
- [ side :  string ->  buy (bid) or sell (sell)
  , price : Float
  , size : Float
  ]

for each change
function 1 -> parse the float values of each change 

function 2 -> 
 - case  buy or sell 
 - compare the change price against each price in the list,
 - if a match is found set the new size 