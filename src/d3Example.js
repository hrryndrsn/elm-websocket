
/////////////////////////////////////////////////////////////////////////////////////////////////
//d3
var city = 'New York';
var width = window.innerWidth * 0.7;
var height = window.innerHeight * 0.4;
var margin = {top: 20, bottom: 20, left: 20, right: 20};


// // dataset of city temperatures across time
var fetchAndClean = d3.tsv("data.tsv", function(d) {
  var arr = [];
  arr.push(d);
  return arr
})

fetchAndClean.then((data) => {
    data.forEach(d => {
      d.date = d3.timeParse("%Y%m%d")(d[0].date);
      d.date = new Date(d.date); // x
      d[city] = ++d[0][city]; // y
    })
  
    //x scale
    var xExtent = d3.extent(data, d => d.date)
    var xScale = d3.scaleTime()
      .domain(xExtent)
      .range([0, width])
  
    //y scale
    var yExtent = d3.extent(data, d => d[city])
    var yScale = d3.scaleLinear()
      .domain(yExtent)
      .range([height - margin.bottom,  margin.top])
  
    //height scale
    var heightScale = d3.scaleLinear()
      .domain(yExtent)
      .range([0, height - margin.top - margin.bottom])
    
      //create rectangles
    var svg = d3.select('svg');
    var rect = svg.selectAll('rect')
      .data(data)
      .enter().append('rect')
      .attr('width', 2)
      .attr('height', (d) => heightScale(d[city]))
      .attr('x', (d) => xScale(d.date))
      .attr('y', (d) => yScale(d[city]))
      .attr('fill', (d) => "black")
      .attr('stroke', (d) => "white")
      
      var xAxis = d3.axisBottom(xScale)
      
      var yAxis = d3.axisLeft()
      .scale(yScale)
      
      svg.append('g')
        .attr('transform', 'translate(' +[0, height - margin.bottom] +')')
        .call(xAxis);
      svg.append('g')
        .attr('transform', 'translate(' + [margin.left, 0] +')')
        .call(yAxis);
    
  
    });