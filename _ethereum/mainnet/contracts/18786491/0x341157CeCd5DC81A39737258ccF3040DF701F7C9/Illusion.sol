// .-..-.  .-.               _             
// : :: :  : :              :_;            
// : :: :  : :  .-..-. .--. .-. .--. ,-.,-.
// : :: :_ : :_ : :; :`._-.': :' .; :: ,. :
// :_;`.__;`.__;`.__.'`.__.':_;`.__.':_;:_;
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Illusion {
    event ArtpieceCreated(address indexed creator);
    event ArtpieceTransferred(address indexed oldOwner, address indexed newOwner);
    event BidAccepted(uint256 value, address indexed fromAddress, address indexed toAddress);
    event BidPlaced(uint256 value, address indexed fromAddress);
    event BidWithdrawn(uint256 value, address indexed fromAddress);
    event ListedForSale(uint256 value, address indexed fromAddress, address indexed toAddress);
    event SaleCanceled(uint256 value, address indexed fromAddress, address indexed toAddress);
    event SaleCompleted(uint256 value, address indexed fromAddress, address indexed toAddress);

    error FundsTransfer();
    error InsufficientFunds();
    error ListedForSaleToSpecificAddress();
    error NoBid();
    error NotForSale();
    error NotOwner();
    error NotRoyaltyRecipient();
    error NotYourBid();
    error NullAddress();
    error RoyaltyTooHigh();

    string public constant MANIFEST = (
        'Do you see what I see?' '\n'
    );

    string public constant CORE = (
        '"use strict";let w=window,d=document,b=d.body;d.body.style.touchAction="none",d.body.style.userSelect="none";let c=d.querySelector("canvas");c||(c=d.createElement("canvas"),c.style.display="block",b.appendChild(c));const mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjEyIiBoZWlnaHQ9IjIxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGNsaXAtcnVsZT0iZXZlbm9kZCIgZD0iTTM0IDIwMi44MTNWMjE2aDE3OFYzOGgtMTMuMTg1djE2NC44MTVINDcuMTg1di0uMDAySDM0Wk0xOTcuNjk1IDE0LjY0NVYwSDB2MTk3LjY5NWgxNC42NDVWMTQuNjQ0aDE4My4wNVoiIGZpbGw9IiNmZmYiLz48cGF0aCBkPSJNOTQgOTVhMyAzIDAgMCAxIDMtM2gyMS40NThhMyAzIDAgMCAxIDMgM3YyMS40NThhMyAzIDAgMCAxLTMgM0g5N2EzIDMgMCAwIDEtMy0zVjk1WiIgZmlsbD0iI2ZmZiIvPjwvc3ZnPg",appendSignature=()=>{const e=d.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",b.appendChild(e)};let h={},s={};const glOptions={powerPreference:"high-performance"};mobile&&delete glOptions.powerPreference,window.gl=c.getContext("webgl",glOptions),h.uniform=(e,t)=>{let r=Array.isArray(t)?t.length-1:0,o=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],i={};return i.name=e,i.type=o[r][0],i.value=t||o[r][1],i.inner_type=o[r][2],i.location="",i.dirty=!1,i},s.uniforms=[["u_resolution",[0,0]],["u_time",0],["u_mouse",[0,0]]],s.uniforms.forEach(((e,t)=>s.uniforms[t]=h.uniform(e[0],e[1]))),h.resize=()=>{let e=s.uniforms[0],t={x:h.ix.mouse.x/e.value[0],y:h.ix.mouse.y/e.value[1]},r=window.innerWidth,o=window.innerHeight;s.aspect&&(r>o*s.aspect?r=o*s.aspect:o=r/s.aspect);let i=window.devicePixelRatio;e.value[0]=c.width=r*i,e.value[1]=c.height=o*i,c.style.width=r+"px",c.style.height=o+"px",e.dirty=!0,h.ix.set(c.width*t.x,c.height*t.y)},h.ix={start:{x:0,y:0},mouse:{x:0,y:0}},h.ix.events={start:["pointerdown"],move:["pointermove"],stop:["pointerup"]},h.ix.save=()=>{let e=s.uniforms[2];e.value=[h.ix.mouse.x,h.ix.mouse.y],e.dirty=!0},h.ix.set=(e,t)=>{h.ix.mouse={x:e,y:t},h.ix.save()},h.ix.start=e=>{h.ix.start.x=e.clientX,h.ix.start.y=e.clientY;for(let e of h.ix.events.move)d.addEventListener(e,h.ix.move)},h.ix.move=e=>{h.ix.mouse.x+=(e.clientX-h.ix.start.x)*window.devicePixelRatio,h.ix.mouse.y-=(e.clientY-h.ix.start.y)*window.devicePixelRatio,h.ix.start.x=e.clientX,h.ix.start.y=e.clientY,h.ix.save()},h.ix.stop=()=>{for(let e of h.ix.events.move)d.removeEventListener(e,h.ix.move)},h.buildShader=(e,t)=>{let r=gl.createShader(e);return gl.shaderSource(r,t),gl.compileShader(r),r},h.initProgram=(e,t)=>{window.program=s.program=gl.createProgram();const r=h.buildShader(gl.VERTEX_SHADER,t),o=h.buildShader(gl.FRAGMENT_SHADER,e);gl.attachShader(s.program,r),gl.attachShader(s.program,o),gl.linkProgram(s.program),gl.getShaderParameter(r,gl.COMPILE_STATUS)||console.error("V: "+gl.getShaderInfoLog(r)),gl.getShaderParameter(o,gl.COMPILE_STATUS)||console.error("F: "+gl.getShaderInfoLog(o)),gl.getProgramParameter(s.program,gl.LINK_STATUS)||console.error("P: "+gl.getProgramInfoLog(s.program));for(let e in s.uniforms){let t=s.uniforms[e];t.location=gl.getUniformLocation(s.program,t.name),t.dirty=!0}let i=Float32Array.of(-1,1,-1,-1,1,1,1,-1),c=gl.createBuffer(),n=gl.getAttribLocation(s.program,"p");gl.bindBuffer(gl.ARRAY_BUFFER,c),gl.bufferData(gl.ARRAY_BUFFER,i,gl.STATIC_DRAW),gl.enableVertexAttribArray(n),gl.vertexAttribPointer(n,2,gl.FLOAT,!1,0,0),gl.useProgram(s.program)},s.pixel=new Uint8Array(4),h.render=()=>{gl.viewport(0,0,c.width,c.height);let e=s.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let t=s.uniforms.filter((e=>e.dirty));for(let e in t)gl[t[e].type](t[e].location,t[e].value),t[e].dirty=!1;gl.drawArrays(gl.TRIANGLE_STRIP,0,4),gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,s.pixel),requestAnimationFrame(h.render)};const init=async()=>{if(gl){const e="attribute vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}",t="precision highp float;const vec3 v=vec3(.580392156862745),f=vec3(.901960784313726);uniform vec2 u_resolution;uniform float u_time;uniform vec2 u_mouse;const vec3 m=vec3(10,20,50),i=vec3(5,20,40);vec3 t(vec3 v,vec4 f){return v+2.*cross(f.xyz,cross(f.xyz,v)+v*f.w);}vec3 s(vec3 v,float f){return t(v,vec4(0,0,sin(f/2.),cos(f/2.)));}float s(float v){vec3 f=fract(vec3(v)*443.8975);f+=dot(f,f.yzx+19.19);return fract((f.x+f.y)*f.z);}float t(float v){float f=floor(v);return mix(s(f),s(f+1.),smoothstep(0.,1.,fract(v)));}float s(vec3 v,vec3 f,vec3 y,float c){float s=dot(f,f),i,r;vec3 m=v-y;i=2.*dot(f,m);r=dot(m,m)-c*c;return i*i-4.*s*r<0.?-1.:(-i-sqrt(i*i-4.*s*r))/(2.*s);}vec2 s(vec3 v,vec3 f,out vec3 m){float r=.7;vec3 i=vec3(0,0,-r);for(int u=0;u<8;u++){float c=s(v,f,i,r);if(c!=-1.)return m=normalize(v+f*c-i),vec2(c,0);i.z-=r;r*=1.5;i.z-=r;}return vec2(1e3,0);}vec2 n(vec3 v){float f=1e3,r=.7;vec3 i=vec3(0,0,-r);for(int u=0;u<7;u++){vec3 m=v-i;float c=length(m)-r;if(c<f)f=c;i.z-=r;r*=1.5;i.z-=r;}return vec2(f,0);}float n(vec3 v,vec3 f){float i=1.,r=.01,u=1.,m=length(v);u=m<=1.1?0.:m<4.05?.37:m<7.4?.476:m<12.5?.728:.476;for(int c=0;c<10;c++){float s=n(v+r*f).x,d=s/r;i=min(i,d);r+=clamp(s,u,1.);if(i<=-1.||r>1e3)break;}return clamp(i,0.,1.);}vec3 n(){vec3 v=gl_FragCoord.xyy,f;v=vec3(dot(v,vec3(127.1,311.7,74.7)),dot(v,vec3(269.5,183.3,246.1)),dot(v,vec3(113.5,271.9,124.6)));f=-1.+2.*fract(sin(v)*43758.5453123);return fract(555.*sin(777.*f))/256.;}vec3 d(vec3 v){vec2 f=gl_FragCoord.xy/u_resolution.xy;float i=(f.x+4.)*(f.y+4.)*(1e2+u_time);vec3 r=vec3(mod((mod(i,13.)+1.)*(mod(i,123.)+1.),.01)-.005)*.01*1e2;v*=1.-r;return v*(1.-r);}vec3 e(vec3 v){v=d(v);v+=n();return v;}vec3 d(inout vec3 c,inout vec3 r,float d){vec3 u,y,e;vec2 t=s(c,r,u);y=c+t.x*r;e=vec3(0);if(t.x>=1e3)e=f;else{y+=u*.01;vec3 z=vec3(0,1,-.5),g=normalize(i-y),o=normalize(m);z=s(z,-d);g=s(g,d);o=s(o,d);g.z+=.5+.6*cos(d*2.);z.z+=.2+.2*cos(d*3.5);o.z+=.2+.5*cos(d)*sin(d*2.);float x=dot(u,normalize(z)),C=dot(g,u),w=(x+C+1.)/2.,F=n(y,o);w*=mix(1.,F,.91);e=mix(f,v,w);}return e;}vec3 d(float v,float f){float c=sin(f);return vec3(50.*c*cos(v),50.*cos(f),50.*c*sin(v));}vec3 e(vec2 v,float f){float r=.5+.5*sin(f-1.570795),c=r*(t(f/2.)-.5),i;v.x+=.00375*c*2.;i=r*(t(f/2.+17.)-.5);v.y+=.00375*i*2.;return d(-v.x*(2.*acos(-1.)),v.y*3.14159);}mat3 r(vec3 v,vec2 f){vec3 i=normalize(vec3(0)-v),m=normalize(cross(vec3(0,floor(mod(f.y,2.))==0.?-1.:1.,0),i));return mat3(m,cross(i,m),i);}vec3 d(){float v=u_time,f,i;vec3 c=vec3(0),m;vec2 u=vec2(.25,-.5),g;m=e(u,2.*acos(-1.)*(v/10.));mat3 s=r(m,u);g=gl_FragCoord.xy;f=.5+.5*sin(g.x*147.)*sin(g.y*131.);i=smoothstep(0.,1.,4.*cos(2.*acos(-1.)*v/20.));for(int y=0;y<1;y++)for(int z=0;z<1;z++){vec2 t=vec2(y,z)/float(1)-.5,o=(gl_FragCoord.xy+t-.5*u_resolution.xy)*.0799573742465801/u_resolution.y;vec3 F=normalize(s*vec3(o,1));float x=v-.1*(float(z+y)+f)/float(1),w;w=2.*acos(-1.)*(x-i)/10.;c.x+=d(m,F,w).x;w=2.*acos(-1.)*x/10.;c.y+=d(m,F,w).y;w=2.*acos(-1.)*(x+i)/10.;c.z+=d(m,F,w).z;}c/=float(1);return c;}void main(){vec3 v=d();gl_FragColor=vec4(e(v),1);}";h.initProgram(t,e),h.resize(),h.ix.set(c.width/2,c.height/2),h.render();for(let e of h.ix.events.start)d.addEventListener(e,h.ix.start);for(let e of h.ix.events.stop)d.addEventListener(e,h.ix.stop);window.addEventListener("resize",h.resize),appendSignature()}else{const e=d.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="Your browser does not support WebGL.",b.append(e)}};init();'
    );

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert NotOwner();
        }

        _;
    }

    modifier onlyRoyaltyRecipient() {
        if (royaltyRecipient != msg.sender) {
            revert NotRoyaltyRecipient();
        }

        _;
    }

    struct Offer {
        bool active;
        uint256 value;
        address toAddress;
    }

    struct Bid {
        bool active;
        uint256 value;
        address fromAddress;
    }

    address public owner;

    Offer public currentOffer;

    Bid public currentBid;

    address public royaltyRecipient;

    uint256 public royaltyPercentage;

    mapping (address => uint256) public pendingWithdrawals;

    constructor(uint256 _royaltyPercentage) {
        if (_royaltyPercentage >= 100) {
            revert RoyaltyTooHigh();
        }

        owner = msg.sender;
        royaltyRecipient = msg.sender;
        royaltyPercentage = _royaltyPercentage;

        emit ArtpieceCreated(msg.sender);
    }

    function name() public view virtual returns (string memory) {
        return 'Illusion';
    }

    function symbol() public view virtual returns (string memory) {
        return 'I';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Illusion', '</title>'

                    '<meta name="viewport" content="width=device-width, initial-scale=1" />'

                    '<style>html,body{background:#969696;margin:0;padding:0;overflow:hidden;}</style>'
                '</head>'

                '<body>'
                    '<script type="text/javascript">',
                        CORE,
                    '</script>'
                '</body>'
            '</html>'
        );
    }

    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];

        pendingWithdrawals[msg.sender] = 0;

        _sendFunds(amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert NullAddress();
        }

        _transferOwnership(newOwner);

        if (currentBid.fromAddress == newOwner) {
            uint256 amount = currentBid.value;

            currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

            pendingWithdrawals[newOwner] += amount;
        }

        if (currentOffer.active) {
            currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });
        }
    }

    function listForSale(uint256 salePriceInWei) public onlyOwner {
        currentOffer = Offer({ active: true, value: salePriceInWei, toAddress: address(0) });

        emit ListedForSale(salePriceInWei, msg.sender, address(0));
    }

    function listForSaleToAddress(uint256 salePriceInWei, address toAddress) public onlyOwner {
        currentOffer = Offer({ active: true, value: salePriceInWei, toAddress: toAddress });

        emit ListedForSale(salePriceInWei, msg.sender, toAddress);
    }

    function cancelFromSale() public onlyOwner {
        Offer memory oldOffer = currentOffer;

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });

        emit SaleCanceled(oldOffer.value, msg.sender, oldOffer.toAddress);
    }

    function buyNow() public payable {
        if (!currentOffer.active) {
            revert NotForSale();
        }

        if (currentOffer.toAddress != address(0) && currentOffer.toAddress != msg.sender) {
            revert ListedForSaleToSpecificAddress();
        }

        if (msg.value != currentOffer.value) {
            revert InsufficientFunds();
        }

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });

        uint256 royaltyAmount = _calcRoyalty(msg.value);

        pendingWithdrawals[owner] += msg.value - royaltyAmount;
        pendingWithdrawals[royaltyRecipient] += royaltyAmount;

        emit SaleCompleted(msg.value, owner, msg.sender);

        _transferOwnership(msg.sender);
    }

    function placeBid() public payable {
        if (msg.value <= currentBid.value) {
            revert InsufficientFunds();
        }

        if (currentBid.value > 0) {
            pendingWithdrawals[currentBid.fromAddress] += currentBid.value;
        }

        currentBid = Bid({ active: true, value: msg.value, fromAddress: msg.sender });

        emit BidPlaced(msg.value, msg.sender);
    }

    function acceptBid() public onlyOwner {
        if (!currentBid.active) {
            revert NoBid();
        }

        uint256 amount = currentBid.value;
        address bidder = currentBid.fromAddress;

        currentOffer = Offer({ active: false, value: 0, toAddress: address(0) });
        currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

        uint256 royaltyAmount = _calcRoyalty(amount);

        pendingWithdrawals[owner] += amount - royaltyAmount;
        pendingWithdrawals[royaltyRecipient] += royaltyAmount;

        emit BidAccepted(amount, owner, bidder);

        _transferOwnership(bidder);
    }

    function withdrawBid() public {
        if (msg.sender != currentBid.fromAddress) {
            revert NotYourBid();
        }

        uint256 amount = currentBid.value;

        currentBid = Bid({ active: false, value: 0, fromAddress: address(0) });

        _sendFunds(amount);

        emit BidWithdrawn(amount, msg.sender);
    }

    function setRoyaltyRecipient(address newRoyaltyRecipient) public onlyRoyaltyRecipient {
        if (newRoyaltyRecipient == address(0)) {
            revert NullAddress();
        }

        royaltyRecipient = newRoyaltyRecipient;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;

        owner = newOwner;

        emit ArtpieceTransferred(oldOwner, newOwner);
    }

    function _sendFunds(uint256 amount) internal virtual {
        (bool success, ) = msg.sender.call{value: amount}('');

        if (!success) {
            revert FundsTransfer();
        }
    }

    function _calcRoyalty(uint256 amount) internal virtual returns (uint256) {
        return (amount * royaltyPercentage) / 100;
    }
}
