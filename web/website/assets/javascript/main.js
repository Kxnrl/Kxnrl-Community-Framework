var err=0,day=0,crt=4399,servers=new Array;function initServers(){getServers(),setInterval(refresh,1e3)}function refresh(){return 4399==crt?($("#countdown").html("Refreshing in ∞ seconds"),!1):4357==crt?($("#countdown").html("Refreshing..."),!1):0==--crt?(crt=4357,getServers(),!1):($("#countdown").html("Refreshing in "+crt+" seconds"),!0)}function getServers(){$("#countdown").html("Refreshing..."),$.getJSON("//api.kxnrl.com/ICommunityServersStatus/v1/?secert=unencrypted&utm_src=magicgirl",function(e){e.reload&&setTimeout(function(){location.reload(!0)},1e3);for(var t=0;t<e.servers.length;++t){var r=$("#serversList tr#r"+t);r.length||($("#serversList").append('<tr id="r'+t+'"><td id="ttl"> </td><td id="mod"></td><td id="vac"></td><td id="srv"></td><td id="map"></td><td id="gmp"></td><td id="ply"></td><td id="act"><a href="steam://connect/'+e.servers[t].adr+'" class="btn btn-success btn-sm"><i class="fa fa-steam fa-1g" aria-hidden="true"></i> Connect</a></td></tr>'),r=$("#serversList tr#r"+t),servers[t]=!0),r=r[0],e.servers[t].err?r.setAttribute("class","bg-danger"):r.setAttribute("class","bg-info"),r.children.mod.innerHTML='<img src="assets/image/'+e.servers[t].mod+'.png" width="24" height="24" />',r.children.vac.innerHTML='<img src="assets/image/'+e.servers[t].vac+'.png" width="24" height="24" />',r.children.srv.innerHTML=e.servers[t].srv,r.children.map.innerHTML=e.servers[t].map,r.children.gmp.innerHTML=e.servers[t].gmp,r.children.srv.setAttribute("style","text-align: left"),r.children.map.setAttribute("style","text-align: left"),r.children.ply.innerHTML=e.servers[t].ply.current+" / "+e.servers[t].ply.maximum}crt=45,err=0}).fail(function(e){crt=9,err=1,console.log("Failed to ajax getJSON: "+e)})}window.onload=function(){initServers();/Android/.test(navigator.userAgent),window.cordova,/Edge/.test(navigator.userAgent),/Firefox/.test(navigator.userAgent);var e=/Google Inc/.test(navigator.vendor),t=/CriOS/.test(navigator.userAgent),r=(!!window.chrome&&/Edge/.test(navigator.userAgent),/Trident/.test(navigator.userAgent),/(iPhone|iPad|iPod)/.test(navigator.platform));/OPR/.test(navigator.userAgent),/Safari/.test(navigator.userAgent)&&/Chrome/.test(navigator.userAgent),"ontouchstart"in window||window.DocumentTouch&&(document,DocumentTouch),"registerElement"in document&&"import"in document.createElement("link")&&document.createElement("template");if(!e&&!t&&!r){var n=document.createElement("audio");n.style.display="none",n.src="//music.kxnrl.com/musics/netease/29819851.mp3",n.autoplay=!1,n.loop=!0,document.body.appendChild(n),n.play()}};