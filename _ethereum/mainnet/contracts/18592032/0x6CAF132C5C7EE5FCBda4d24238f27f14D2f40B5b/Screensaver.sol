//    _|_|_|                                                                                                        
//  _|          _|_|_|  _|  _|_|    _|_|      _|_|    _|_|_|      _|_|_|    _|_|_|  _|      _|    _|_|    _|  _|_|  
//    _|_|    _|        _|_|      _|_|_|_|  _|_|_|_|  _|    _|  _|_|      _|    _|  _|      _|  _|_|_|_|  _|_|      
//        _|  _|        _|        _|        _|        _|    _|      _|_|  _|    _|    _|  _|    _|        _|        
//  _|_|_|      _|_|_|  _|          _|_|_|    _|_|_|  _|    _|  _|_|_|      _|_|_|      _|        _|_|_|  _|  
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Screensaver {
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
        'This is our way of seeing things, stranger in a strange land.' '\n'
    );

    string public constant CORE = (
        '"use strict";let w=window,d=document,b=d.body;b||(d.createElement("body"),d.documentElement.appendChild(b)),d.body.style.touchAction="none",d.body.style.userSelect="none";let c=d.querySelector("canvas");c||(c=d.createElement("canvas"),c.style.display="block",b.appendChild(c));const mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjMiIHZpZXdCb3g9IjAgMCAyNCAyMyIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik02IDBIN1YxSDhWMkg5SDEwSDExVjFIMTJIMTNIMTRIMTVIMTZIMTdIMThWMEgxOUgyMFYxSDIxVjBIMjJIMjNIMjRWMVYyVjNWNFY1VjZWN1Y4VjlWMTBWMTFIMjNWMTJWMTNIMjJWMTRWMTVWMTZWMTdWMThWMTlWMjBWMjFIMjNWMjJIMjJIMjFIMjBIMTlIMThIMTdIMTZIMTVWMjNIMTRIMTNIMTJIMTFIMTBIOUg4SDdWMjJINkg1SDRIM0gySDFWMjFWMjBWMTlWMThWMTdWMTZWMTVIMlYxNFYxM1YxMlYxMVYxMFY5VjhIM1Y5VjEwVjExVjEyVjEzVjE0VjE1VjE2SDJWMTdWMThWMTlWMjBWMjFIM0g0SDVINkg3SDhWMjJIOUgxMEgxMUgxMkgxM0gxNFYyMUgxNUgxNkgxN0gxOEgxOUgyMFYyMEgyMVYxOVYxOFYxN1YxNkgyMFYxNVYxNEgyMVYxM1YxMkgyMlYxMVYxMEgyM1Y5VjhWN1Y2VjVWNFYzVjJWMUgyMlYySDIxVjNIMjBWMkgxOUgxOEgxN0gxNkgxNUgxNEgxM0gxMlYzSDExSDEwSDlIOEg3VjJINkg1SDRIM0gyVjNWNFY1VjZWN1Y4SDFWN1Y2VjVWNFYzVjJIMFYxSDFIMkgzSDRINUg2VjBaTTEwIDlIMTFIMTJIMTNIMTRWMTBWMTFWMTJWMTNIMTNIMTJIMTFIMTBWMTJWMTFWMTBWOVoiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPgo=",appendSignature=()=>{const e=d.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",b.appendChild(e)};let h={},s={};const glOptions={powerPreference:"high-performance"};mobile&&delete glOptions.powerPreference;let gl=c.getContext("webgl",glOptions);if(h.uniform=(e,v)=>{let t=Array.isArray(v)?v.length-1:0,l=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],c={};return c.name=e,c.type=l[t][0],c.value=v||l[t][1],c.inner_type=l[t][2],c.location="",c.dirty=!1,c},s.uniforms=[["u_resolution",[0,0]],["u_time",0],["u_mouse",[0,0]]],s.uniforms.forEach(((e,v)=>s.uniforms[v]=h.uniform(e[0],e[1]))),h.resize=()=>{let e=s.uniforms[0],v={x:h.ix.mouse.x/e.value[0],y:h.ix.mouse.y/e.value[1]},t=window.devicePixelRatio;e.value[0]=c.width=w.innerWidth*t,e.value[1]=c.height=w.innerHeight*t,e.dirty=!0,c.style.width="100%",c.style.height="100%",h.ix.set(c.width*v.x,c.height*v.y)},h.ix={start:{x:0,y:0},mouse:{x:0,y:0}},h.ix.events={start:["mousedown","touchstart"],move:["mousemove","touchmove"],stop:["mouseup","touchend"]},w.PointerEvent&&(h.ix.events={start:["pointerdown"],move:["pointermove"],stop:["pointerup"]}),h.ix.save=()=>{let e=s.uniforms[2];e.value=[h.ix.mouse.x,h.ix.mouse.y],e.dirty=!0},h.ix.set=(e,v)=>{h.ix.mouse={x:e,y:v},h.ix.save()},h.ix.start=e=>{h.ix.start.x=e.clientX,h.ix.start.y=e.clientY;for(let e of h.ix.events.move)d.addEventListener(e,h.ix.move)},h.ix.move=e=>{h.ix.mouse.x+=(e.clientX-h.ix.start.x)*window.devicePixelRatio,h.ix.mouse.y-=(e.clientY-h.ix.start.y)*window.devicePixelRatio,h.ix.start.x=e.clientX,h.ix.start.y=e.clientY,h.ix.save()},h.ix.stop=()=>{for(let e of h.ix.events.move)d.removeEventListener(e,h.ix.move)},h.buildShader=(e,v)=>{let t=gl.createShader(e);return gl.shaderSource(t,v),gl.compileShader(t),t},h.initProgram=(e,v)=>{s.program=gl.createProgram();const t=h.buildShader(gl.VERTEX_SHADER,v),l=h.buildShader(gl.FRAGMENT_SHADER,e);gl.attachShader(s.program,t),gl.attachShader(s.program,l),gl.linkProgram(s.program);for(let e in s.uniforms){let v=s.uniforms[e];v.location=gl.getUniformLocation(s.program,v.name),v.dirty=!0}let c=Float32Array.of(-1,1,-1,-1,1,1,1,-1),o=gl.createBuffer(),r=gl.getAttribLocation(s.program,"p");gl.bindBuffer(gl.ARRAY_BUFFER,o),gl.bufferData(gl.ARRAY_BUFFER,c,gl.STATIC_DRAW),gl.enableVertexAttribArray(r),gl.vertexAttribPointer(r,2,gl.FLOAT,!1,0,0),gl.useProgram(s.program)},s.pixel=new Uint8Array(4),h.render=()=>{gl.viewport(0,0,c.width,c.height);let e=s.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let v=s.uniforms.filter((e=>e.dirty));for(let e in v)gl[v[e].type](v[e].location,v[e].value),v[e].dirty=!1;gl.drawArrays(gl.TRIANGLE_STRIP,0,4),gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,s.pixel),requestAnimationFrame(h.render)},gl){const e="attribute vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}",v=`${["#ifdef GL_ES","precision highp float;","#endif","#define AA "+(mobile?1:2),"#define R(a)mat2(cos(a),sin(a),-sin(a),cos(a))"].map((e=>`${e}${String.fromCharCode(10)}`)).join("")}uniform vec2 u_resolution;uniform float u_time;uniform vec2 u_mouse;const vec3 v=vec3(-.35,.05,4.3);const vec3 f=vec3(.88),l=vec3(2),c=vec3(1.42,-.97,-.1822),y=vec3(.768,.036,-.65),n=vec3(-.8,1.25,.666);const vec3 x=vec3(0,.5,0);const vec3 m=vec3(0,.2,0);const vec3 z=vec3(.015,.2,0);float a,r;vec3 s(vec3 v,vec4 l){return v+2.*cross(l.xyz,cross(l.xyz,v)+v*l.w);}vec3 h(vec3 v,float l){return s(v,vec4(sin(l/2.),0,0,cos(l/2.)));}vec3 p(vec3 v,float l){return s(v,vec4(0,sin(l/2.),0,cos(l/2.)));}vec3 e(vec3 v,float l){return s(v,vec4(0,0,sin(l/2.),cos(l/2.)));}mat4 t(vec3 v,float l){v=normalize(v);float x=sin(l),f=cos(l),y=1.-f;return mat4(y*v.x*v.x+f,y*v.x*v.y-v.z*x,y*v.z*v.x+v.y*x,0.,y*v.x*v.y+v.z*x,y*v.y*v.y+f,y*v.y*v.z-v.x*x,0.,y*v.z*v.x-v.y*x,y*v.y*v.z+v.x*x,y*v.z*v.z+f,0.,0.,0.,0.,1.);}vec3 e(vec3 v){float x=(v.x+16.)/116.,y=v.y/5e2+x,l=x-v.z/2e2;return vec3(95.047*(y>.206897?y*y*y:(y-16./116.)/7.787),1e2*(x>.206897?x*x*x:(x-16./116.)/7.787),108.883*(l>.206897?l*l*l:(l-16./116.)/7.787));}vec3 h(vec3 v){vec3 l=v/1e2*mat3(3.2406,-1.5372,-.4986,-.9689,1.8758,.0415,.0557,-.204,1.057),f;f.x=l.x>.0031308?1.055*pow(l.x,1./2.4)-.055:12.92*l.x;f.y=l.y>.0031308?1.055*pow(l.y,1./2.4)-.055:12.92*l.y;f.z=l.z>.0031308?1.055*pow(l.z,1./2.4)-.055:12.92*l.z;return f;}vec3 p(vec3 v){float l=v.y,y=v.x,f=v.z;l=50.*(l+1.);y*=127.;f*=127.;return h(e(vec3(l,y,f)));}vec3 s(vec3 v){v-=vec3(.1,.8,0);v.x-=.151;v.y-=.007;v.z+=.253;v.y*=2.;return v;}vec3 t(vec3 v){vec2 l=vec2(0);v=p(v,l.y);v=e(v,l.x);v=(vec4(v,1)*t(x,2.*acos(-1.)*u_time/20.)).xyz;v=(vec4(v,1)*t(m,2.*acos(-1.)*u_time/20.)).xyz;v=(vec4(v,1)*t(z,2.*acos(-1.)*u_time/10.)).xyz;v-=n;v-=y;v=h(v,c.x);v=p(v,c.y);v=e(v,c.z);v+=n;return v;}vec3 w(vec3 v){v=t(v);const vec3 l=vec3(0,-1,0);v+=l;v=h(v,-1.570795);v-=l;return v;}vec3 d(vec3 v){v=t(v);v=s(v);return p(v);}float d(float v,float l){float y=max(.004-abs(v-l),0.);return min(v,l)-y*y*.25/.004;}float w(float v,float l){return-d(v,-l);}float u(vec3 v){vec3 l=vec3(0);v=w(v);float f=length(v-l-vec3(1.895,2.0474,-1.4359))-3.;{vec3 x=v-l-vec3(-4.3351,-3.9846,-29.485);f=w(length(x)-30.,f);}{vec3 x=v-l-vec3(.53786,-21.914,-19.741);f=w(length(x)-30.,f);}{vec3 x=v-l-vec3(-1.7741,45.048,24.641);f=w(length(x)-50.,f);}{vec3 x=v-l-vec3(-2.1311,67.427,45.365);f=w(length(x)-50.,f);}{vec3 x=v-l-vec3(39.081,8.7784,31.357);f=w(length(x)-49.86,f);}{vec3 x=v-l-vec3(28.62,12.917,40.135);f=w(length(x)-50.,f);}{vec3 x=v-l-vec3(-.16214,54.491,60.143);f=w(length(x)-80.,f);}{vec3 x=v-l-vec3(15.418,17.653,77.38);f=w(length(x)-80.,f);}{vec3 x=v-l-vec3(-40.298,-9.302,68.882);f=w(length(x)-79.98,f);}{vec3 x=v-l-vec3(-51.08,20.818,59.105);f=w(length(x)-80.01,f);}{vec3 x=v-l-vec3(17.042,-1.99,78.88);f=w(length(x)-79.96,f);}{vec3 x=v-l-vec3(10.826,.01142,-28.229);f=w(length(x)-30.,f);}return f;}vec2 i(vec3 v){float x=u(v);return vec2(x,1);}vec2 d(vec3 v,vec3 x,float l){float f=0.,y=0.;for(int r=0;r<128;r++){vec3 m=v+x*f;vec2 c=i(m);y=c.y;f+=c.x*l;if(abs(c.x)<.001||f>10.)break;}return vec2(f,y);}vec3 A(vec3 v){vec2 l=vec2(.02,0);vec3 x=vec3(l.x,0,0),f=vec3(0,l.x,0),y=vec3(0,0,l);return normalize(vec3(i(v+x).x-i(v-x).x,i(v+f).x-i(v-f).x,i(v+y).x-i(v-y).x));}vec3 A(vec3 v,vec3 x,vec3 f){vec3 y=vec3(.31),r=y*.25,c=normalize(l);float m=clamp(dot(f,c),0.,1.);r+=y*m;m=clamp(dot(x,reflect(c,f)),0.,1.),r+=pow(m,15.)*.17;return r;}float A(vec3 v,vec3 x){float f=-.2,y,l;f*=f;y=-dot(x,v);l=1.-y;return f+(1.-f)*pow(l,5.);}vec3 e(vec3 v,vec3 x,vec3 y){vec3 l=v,c,m,z,n,i;vec2 a=d(l+x*.01,x,-1.),s;c=A(l);m=l+y*.01;m-=c*.001;s=d(m,y,-1.);if(s.x<=0.)a.x=0.;v=l+x*.01;z=1.-d(v);z=clamp(z,0.,1.);float u=4.*(mod(r/4.,2.*acos(-1.))/(2.*acos(-1.))),e;u=u>3.?pow(max(0.,abs(1.-2.*(4.-u))*2.-1.),2.):1.;n=exp(-10.*u*z*a.x);e=clamp(a.x,0.,1.);i=mix(f,vec3(.4),e);i*=n;return clamp(i,0.,1.);}vec3 i(vec3 v,vec3 x){vec3 l=vec3(0),y;vec2 m=d(v,x,1.);y=v+m.x*x;if(m.x>=10.)return f;if(m.y==1.){vec3 c=A(y),r;l=A(y,x,c);float i=A(x,c);i=clamp(i,0.,1.);r=e(y,refract(x,c,1./1.5),x);l+=mix(r,f,i);}return l;}vec3 h(float v,float x,float l){float y=sin(l);return vec3(v*y*cos(x),v*cos(l),v*y*sin(x));}void main(){a=u_time/5.;r=2.*acos(-1.)*a;vec3 l=vec3(u_mouse/u_resolution,0),f,x,y,c;l+=v;if(l.y==0.)l.y=.001;float m=l.y*3.14159,z;f=h(l.z,-l.x*(2.*acos(-1.)),m);x=normalize(vec3(0)-f);z=floor(mod(l.y,2.))==0.?1.:-1.;y=normalize(cross(vec3(0,z,0),x));mat3 u=mat3(y,cross(x,y),x);c=vec3(0);for(int s=0;s<AA;s++)for(int n=0;n<AA;n++){vec2 e=vec2(s,n)/float(AA)-.5,A=(gl_FragCoord.xy+e-.5*u_resolution.xy)*1.16920251224065/u_resolution.y;c+=i(f,normalize(u*vec3(A,1)));}c/=float(AA*AA);gl_FragColor=vec4(c,1);}`;h.initProgram(v,e),h.resize(),h.ix.set(c.width/2,c.height/2),h.render();for(let e of h.ix.events.start)d.addEventListener(e,h.ix.start);for(let e of h.ix.events.stop)d.addEventListener(e,h.ix.stop);window.addEventListener("resize",h.resize),appendSignature()}else{const e=d.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="Your browser does not support WebGL.",b.append(e)}'
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
        return 'Screensaver';
    }

    function symbol() public view virtual returns (string memory) {
        return 'SS';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Screensaver', '</title>'

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
