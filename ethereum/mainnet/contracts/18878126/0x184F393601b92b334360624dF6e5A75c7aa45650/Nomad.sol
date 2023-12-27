// |\| () |\/| /\ |)
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Nomad {
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
        'Countless ways.' '\n'
    );

    string public constant CORE = (
        '"use strict";let w=window,d=document,b=d.body;d.body.style.touchAction="none",d.body.style.userSelect="none";let c=d.querySelector("canvas");c||(c=d.createElement("canvas"),c.style.display="block",b.appendChild(c));const mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),frag_shader_string="precision highp float;uniform vec2 u_resolution,u_mouse;uniform float u_time;float v,f;mat2 t(){float v=2.*acos(-1.)*.1*.33;return mat2(cos(v),sin(v),-sin(v),cos(v));}vec3 t(vec3 v){v=vec3(dot(v,vec3(127.1,311.7,74.7)),dot(v,vec3(269.5,183.3,246.1)),dot(v,vec3(113.5,271.9,124.6)));return-1.+2.*fract(sin(v)*43758.5453123);}float m(float v){v=fract(v*.1031);v*=v+33.33;v*=v+v;return fract(v);}float n(float v){return mix(m(floor(v)),m(floor(v+1.)),smoothstep(0.,1.,fract(v)))*2.-1.;}float n(vec3 v){const vec3 f=vec3(1560,21,1713);vec3 x=fract(v),r;float z=dot(floor(v),f);r=x*x*(3.-2.*x);return mix(mix(mix(m(z+dot(f,vec3(0))),m(z+dot(f,vec3(1,0,0))),r.x),mix(m(z+dot(f,vec3(0,1,0))),m(z+dot(f,vec3(1,1,0))),r.x),r.y),mix(mix(m(z+dot(f,vec3(0,0,1))),m(z+dot(f,vec3(1,0,1))),r.x),mix(m(z+dot(f,vec3(0,1,1))),m(z+dot(f,vec3(1))),r.x),r.y),r.z);}float x(vec2 v){float z=0.,f=.99,x=10.;for(int r=0;r<9;r++)z+=f*n(vec3(v,x)),v*=t(),v*=2.,x*=1.,f*=.5;return z;}vec4 m(vec2 f,vec2 m,float y){vec2 z=f/min(m.y,m.x);vec4 r=vec4(0);r.x=x(z*3.3+v);r.y=x(z*3.3+vec2(1));r.z=x(z*3.3+r.xy+vec2(1.7,9.2)+v);r.w=x(z*3.3+r.xz+vec2(80.3,2.8)+v*.33);vec3 n=vec3(.5529),u=n;u=mix(n,vec3(.9333),r.w);return vec4(u,1);}vec4 m(vec2 z,vec2 r){f=1./min(r.x,r.y);float x=.5+.5*sin(z.x*147.)*sin(z.y*131.),u=n(u_time*.05),d;u=pow(u,.6);u=smoothstep(.2,.9,u);d=.8*u;vec4 y=vec4(0,0,0,1);for(int i=0;i<2;i++)for(int w=0;w<2;w++){float s=u_time-.5*(1./15.)*(float(i*2+w)+x)/float(4);vec2 c=z+vec2(w,i)/float(2);v=(s-d)/10.;y.x+=m(c,r,-1.).x;v=s/10.;y.y+=m(c,r,0.).y;v=(s+d)/10.;y.z+=m(c,r,1.).z;}y/=float(4);return y;}void main(){vec4 v=vec4(1);vec2 f=gl_FragCoord.xy;v=m(f,u_resolution);vec3 r=fract(555.*sin(777.*t(f.xyy)))/256.;gl_FragColor=vec4(v.xyz+r,1);}",SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjE2IiBoZWlnaHQ9IjIxNiIgdmlld0JveD0iMCAwIDIxNiAyMTYiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNOCA4SDIwOFYyMDhIOFY4Wk0wIDIxNlYwSDIxNlYyMTZIMFpNOTggMTE4SDExOFY5OEg5OFYxMThaTTkwIDkwVjEyNkgxMjZWOTBIOTBaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4K",appendSignature=()=>{const e=d.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",b.appendChild(e)};let h={},s={};const glOptions={powerPreference:"high-performance"};mobile&&delete glOptions.powerPreference,window.gl=c.getContext("webgl",glOptions),h.uniform=(e,t)=>{let r=Array.isArray(t)?t.length-1:0,i=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],o={};return o.name=e,o.type=i[r][0],o.value=t||i[r][1],o.inner_type=i[r][2],o.location="",o.dirty=!1,o},s.uniforms=[["u_resolution",[0,0]],["u_time",0],["u_mouse",[0,0]]],s.uniforms.forEach(((e,t)=>s.uniforms[t]=h.uniform(e[0],e[1]))),h.resize=()=>{let e=s.uniforms[0],t={x:h.ix.mouse.x/e.value[0],y:h.ix.mouse.y/e.value[1]},r=window.innerWidth,i=window.innerHeight;s.aspect&&(r>i*s.aspect?r=i*s.aspect:i=r/s.aspect);let o=window.devicePixelRatio;e.value[0]=c.width=r*o,e.value[1]=c.height=i*o,c.style.width=r+"px",c.style.height=i+"px",e.dirty=!0,h.ix.set(c.width*t.x,c.height*t.y)},h.ix={start:{x:0,y:0},mouse:{x:0,y:0}},h.ix.events={start:["pointerdown"],move:["pointermove"],stop:["pointerup"]},h.ix.save=()=>{let e=s.uniforms[2];e.value=[h.ix.mouse.x,h.ix.mouse.y],e.dirty=!0},h.ix.set=(e,t)=>{h.ix.mouse={x:e,y:t},h.ix.save()},h.ix.start=e=>{h.ix.start.x=e.clientX,h.ix.start.y=e.clientY;for(let e of h.ix.events.move)d.addEventListener(e,h.ix.move)},h.ix.move=e=>{h.ix.mouse.x+=(e.clientX-h.ix.start.x)*window.devicePixelRatio,h.ix.mouse.y-=(e.clientY-h.ix.start.y)*window.devicePixelRatio,h.ix.start.x=e.clientX,h.ix.start.y=e.clientY,h.ix.save()},h.ix.stop=()=>{for(let e of h.ix.events.move)d.removeEventListener(e,h.ix.move)},h.buildShader=(e,t)=>{let r=gl.createShader(e);return gl.shaderSource(r,t),gl.compileShader(r),r},h.initProgram=(e,t)=>{window.program=s.program=gl.createProgram();const r=h.buildShader(gl.VERTEX_SHADER,t),i=h.buildShader(gl.FRAGMENT_SHADER,e);gl.attachShader(s.program,r),gl.attachShader(s.program,i),gl.linkProgram(s.program),gl.getShaderParameter(r,gl.COMPILE_STATUS)||console.error("V: "+gl.getShaderInfoLog(r)),gl.getShaderParameter(i,gl.COMPILE_STATUS)||console.error("F: "+gl.getShaderInfoLog(i)),gl.getProgramParameter(s.program,gl.LINK_STATUS)||console.error("P: "+gl.getProgramInfoLog(s.program));for(let e in s.uniforms){let t=s.uniforms[e];t.location=gl.getUniformLocation(s.program,t.name),t.dirty=!0}let o=Float32Array.of(-1,1,-1,-1,1,1,1,-1),n=gl.createBuffer(),a=gl.getAttribLocation(s.program,"p");gl.bindBuffer(gl.ARRAY_BUFFER,n),gl.bufferData(gl.ARRAY_BUFFER,o,gl.STATIC_DRAW),gl.enableVertexAttribArray(a),gl.vertexAttribPointer(a,2,gl.FLOAT,!1,0,0),gl.useProgram(s.program)},s.pixel=new Uint8Array(4),h.render=()=>{gl.viewport(0,0,c.width,c.height);let e=s.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let t=s.uniforms.filter((e=>e.dirty));for(let e in t)gl[t[e].type](t[e].location,t[e].value),t[e].dirty=!1;gl.drawArrays(gl.TRIANGLE_STRIP,0,4),gl.readPixels(0,0,1,1,gl.RGBA,gl.UNSIGNED_BYTE,s.pixel),requestAnimationFrame(h.render)};const init=async()=>{if(gl){const e="attribute vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}";h.initProgram(frag_shader_string,e),h.resize(),h.ix.set(c.width/2,c.height/2),h.render();for(let e of h.ix.events.start)d.addEventListener(e,h.ix.start);for(let e of h.ix.events.stop)d.addEventListener(e,h.ix.stop);window.addEventListener("resize",h.resize),appendSignature()}else{const e=d.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="Your browser does not support WebGL.",b.append(e)}};init();'
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
        return 'Nomad';
    }

    function symbol() public view virtual returns (string memory) {
        return 'N';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Nomad', '</title>'

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
