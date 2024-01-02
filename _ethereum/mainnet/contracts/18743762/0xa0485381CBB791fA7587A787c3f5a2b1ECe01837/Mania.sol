// .   ,  ,.  .  . ,  ,.  
// |\ /| /  \ |\ | | /  \ 
// | V | |--| | \| | |--| 
// |   | |  | |  | | |  | 
// '   ' '  ' '  ' ' '  ' 
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Mania {
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
        'It is all about cubes.' '\n'
    );

    string public constant CORE = (
        'const FRAG_DIRECTIVES=["#version 300 es","#ifdef GL_ES","precision highp float;","#endif","out vec4 fragColor;","#define AA 2","#define R(a)mat2(cos(a),sin(a),-sin(a),cos(a))"].map((e=>`${e}${String.fromCharCode(10)}`)).join("");let frag_piece=`${FRAG_DIRECTIVES}uniform vec2 u_resolution,u_mouse;uniform float u_time;const vec2 v=vec2(.5,1);const vec3 m=vec3(.0863,.0745,.0863);float x,f,r;vec4 c[25];float t(vec2 v,vec2 x){vec2 m=abs(v)-x;return length(max(m,0.))+min(max(m.y,m.x),0.);}float t(vec3 v,vec3 x){vec3 m=abs(v)-x;return length(max(m,0.))+min(max(max(m.y,m.x),m.z),0.);}vec3 t(vec3 v){v=vec3(dot(v,vec3(127.1,311.7,74.7)),dot(v,vec3(269.5,183.3,246.1)),dot(v,vec3(113.5,271.9,124.6)));return-1.+2.*fract(sin(v)*43758.5453123);}vec3 n(vec3 v){return clamp(v*(2.51*v+.03)/(v*(2.43*v+.59)+.14),0.,1.);}float n(float v,float x,float y){return min(-y,max(v,x))+length(max(vec2(v,x)+y,vec2(0)));}float n(float v,float x){return n(v,-v,x);}vec3 n(vec3 v,float x){return vec3(n(v.x,x),n(v.y,x),n(v.z,x));}float s(vec3 v){v=fract(v*.3183099+.1);v*=17.;return fract(v.x*v.y*v.z*(v.x+v.y+v.z));}float p(vec3 v){vec3 m=floor(v),x=fract(v);x=x*x*(3.-2.*x);return mix(mix(mix(s(m+vec3(0)),s(m+vec3(1,0,0)),x.x),mix(s(m+vec3(0,1,0)),s(m+vec3(1,1,0)),x.x),x.y),mix(mix(s(m+vec3(0,0,1)),s(m+vec3(1,0,1)),x.x),mix(s(m+vec3(0,1,1)),s(m+vec3(1)),x.x),x.y),x.z);}vec3 i;float l=0.;vec2 y=vec2(0);vec2 e(vec2 v){vec3 m=fract(vec3(v.xyx)*vec3(.1031,.103,.0973));m+=dot(m,m.yzx+33.33);return fract((m.xx+m.yz)*m.zy);}vec2 e(vec3 v,vec2 m){int f=int(m.x+(m.x+1.)*m.y);vec4 u=c[f];float y=u.z,r,z;m=u.xy;vec2 i=vec2(2.*acos(-1.)*x);i.x*=max(m.x*3.,.5);i.y*=max(m.y*3.,.5);v.xy*=R(2.*acos(-1.)*m.x+i.x);v.yz*=R(2.*acos(-1.)*m.y+i.y);v.zx*=R(2.*acos(-1.)*x+2.*acos(-1.)*y);vec3 s=mix(vec3(.25),vec3(.3),y);r=t(v,s);z=t(v-vec3(0,0,s.z*2.-.01),s);z=max(r,z);return vec2(r,z);}vec2 h(vec3 v){float x=1e20,m;vec2 y=round(v.xy),s=sign(v.xy-y);m=1e20;for(int f=0;f<2;f++)for(int r=0;r<2;r++){vec2 z=y+vec2(r,f)*s,u=e(vec3(v.xy-z,v.z),z+vec2(2.5));if(m>u.y)m=u.y,x=2.;if(m>u.x)m=u.x,x=1.;}vec3 f=abs(v)-vec3(vec2(5).xy,1)*.5;return vec2(max(m,min(max(max(f.x,f.y),f.z),0.)+length(max(f,0.))),x);}vec2 u(vec3 v){vec2 m=h(v);return vec2(min(1e2,m.x),m.y);}vec3 w(vec3 v){vec2 m=vec2(.002,0);float x=u(v).x;return normalize(vec3(x-u(v-m.xyy).x,x-u(v-m.yxy).x,x-u(v-m.yyx).x));}vec2 h(vec3 v,vec3 x){l=0.;float m=0.;vec2 f;for(int r=0;r<64;r++){vec3 y=v+x*m;f=u(y);m+=f.x;if(m>20.||abs(f.x)<.001)break;}m=min(m,20.);return vec2(m,f.y);}vec4 p(vec3 v,vec3 m){vec3 x=w(v),f=vec3(1e-5,-10,1e-6),r;f=normalize(v-f);float y=clamp(dot(f,x),0.,1.),s=clamp(1.+dot(m,x),0.,1.),z=clamp(dot(reflect(-f,x),-m),0.,1.);r=mix(vec3(.6745),vec3(1)*2.,pow(y,1.));r+=vec3(1)*pow(s,7.);r+=vec3(1)*pow(z,2.)*.75;return vec4(r,s);}vec4 s(vec2 v,vec2 m){r=0.;vec2 f=(v-.5*m)/min(m.y,m.x),s;vec3 y=vec3(0,0,-10),z,a,A,d,u,c;i=y;z=normalize(vec3(0)-y);a=normalize(vec3(z.z,0,-z.x));A=normalize(f.x*a+f.y*cross(z,a)+z/.56);s=h(y,A);d=y+A*s.x;u=vec3(0);float l=0.,C,e;if(s.x<20.){vec4 t=p(d,A);u=t.xyz;l=mix(1.,0.,step(s.y,1.));}C=smoothstep(3.,10.,length(d));e=p(vec3(f*1e3,x*50.));e=pow(e,.9);c=mix(vec3(.63),vec3(1)*2.,e);u=mix(u,vec3(.8471),C);u=mix(u,c,l);u=n(u);return vec4(u,C);}float d(float v){vec3 m=fract(vec3(v)*443.8975);m+=dot(m,m.yzx+19.19);return fract((m.x+m.y)*m.z);}float a(float v){float m=floor(v);return mix(d(m),d(m+1.),smoothstep(0.,1.,fract(v)));}void A(vec2 v){y=u_mouse/v;vec2 m=y*2.;for(float x=0.;x<26.;x++){float f=floor(x/5.),s=mod(x,5.);vec2 u=vec2(f,s);vec4 r=vec4(1);r.xy=e(u)*2.;r.z=p(vec3(u.x+m.x,u.y+m.y,2));c[int(x)]=r;}}vec4 A(vec2 v,vec2 m){A(m);vec4 r=vec4(0,0,0,1);float y=.5+.5*sin(v.x*147.)*sin(v.y*131.),z=a(u_time*3.);z=pow(z,2.);z=smoothstep(.5,1.,z);for(int u=0;u<AA;u++)for(int i=0;i<AA;i++){float l=u_time-.125*(float(u*AA+i)+y)/float(AA*AA);vec2 d=v+vec2(i,u)/float(AA);x=l/8.;f=2.*acos(-1.)*x;r.xyz+=s(d,m).xyz;}r/=float(AA*AA);return r;}void main(){vec4 v=vec4(m,1);vec2 x=u_resolution,f=gl_FragCoord.xy;float r=length(u_mouse/x*5.-1.);r=clamp(r,0.,1.);v=A(f,x);vec3 y=fract(555.*sin(777.*t(f.xyy)))/256.;fragColor=vec4(v.xyz+y,1);}`;const VERT_DIRECTIVES=["#version 300 es"].map((e=>`${e}${String.fromCharCode(10)}`)).join("");let vert_shader=`${VERT_DIRECTIVES}in vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}`,w=window,d=document,device_ratio=window.devicePixelRatio,pixel=new Uint8Array(4),is_mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),canvas=d.querySelector("canvas");if(document.body.style.touchAction="none",document.body.style.userSelect="none",!canvas){canvas=d.createElement("canvas"),canvas.style.display="block";var body=d.body;body||(body=d.createElement("body")),body.appendChild(canvas),d.documentElement.appendChild(body)}let webglOptions={};is_mobile||(webglOptions={powerPreference:"high-performance"});let webgl=canvas.getContext("webgl2",webglOptions);webgl.program=null,webgl.uniform=(e,t)=>{let r=Array.isArray(t)?t.length-1:0,a=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],o={};return o.name=e,o.type=a[r][0],o.value=t||a[r][1],o.inner_type=a[r][2],o.location="",o.dirty=!1,o},webgl.uniforms=[["u_resolution",[0,0]],["u_time",.001*performance.now()],["u_mouse",[0,0]]],webgl.uniforms.forEach(((e,t)=>webgl.uniforms[t]=webgl.uniform(e[0],e[1]))),webgl.create_shader=(e,t,r)=>{let a=e.createShader(t);return webgl.shaderSource(a,r),webgl.compileShader(a),a},webgl.resize=()=>{canvas.width=w.innerWidth*device_ratio,canvas.height=w.innerHeight*device_ratio,canvas.style.width="100%",canvas.style.height="100%";let e=webgl.uniforms[0];e.value=[canvas.width,canvas.height],e.dirty=!0},webgl.render=()=>{webgl.viewport(0,0,canvas.width,canvas.height);let e=webgl.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let t=webgl.uniforms.filter((e=>1==e.dirty));for(let e in t)webgl[t[e].type](t[e].location,t[e].value),t[e].dirty=!1;webgl.drawArrays(webgl.TRIANGLE_STRIP,0,4),webgl.readPixels(0,0,1,1,webgl.RGBA,webgl.UNSIGNED_BYTE,pixel)},webgl.is_valid=()=>null!=webgl.program,webgl.start_update=()=>{webgl.render(),webgl.frame=requestAnimationFrame(webgl.start_update)},webgl.stop_update=()=>{webgl.frame&&cancelAnimationFrame(webgl.frame)},webgl.change_aa=e=>{frag_piece=frag_piece.replace("#define AA 2",`#define AA ${e}`)};let pointer,load_shader=(e,t)=>{null==t&&(t=vert_shader);let r=webgl;r.stop_update(),r.deleteProgram(r.program),r.program=r.createProgram();const a=webgl.create_shader(r,r.VERTEX_SHADER,t),o=webgl.create_shader(r,r.FRAGMENT_SHADER,e);r.attachShader(r.program,a),r.attachShader(r.program,o),r.linkProgram(r.program);for(let e in webgl.uniforms){let t=webgl.uniforms[e];t.location=r.getUniformLocation(r.program,t.name),t.dirty=!0}let v=Float32Array.of(-1,1,-1,-1,1,1,1,-1),i=r.createBuffer(),c=r.getAttribLocation(r.program,"p");r.bindBuffer(r.ARRAY_BUFFER,i),r.bufferData(r.ARRAY_BUFFER,v,r.STATIC_DRAW),r.enableVertexAttribArray(c),r.vertexAttribPointer(c,2,r.FLOAT,!1,0,0),r.useProgram(r.program),r.resize()},start_shader=(e,t)=>{is_mobile&&webgl.change_aa(1),load_shader(e,t),webgl.start_update()};pointer=w.PointerEvent?{start:["pointerdown"],move:["pointermove"],end:["pointerup"]}:{start:["mousedown","touchstart"],move:["mousemove","touchmove"],end:["mouseup","touchend"]};let drag={update_uniform:e=>{let t=webgl.uniforms[0].value,r=webgl.uniforms[2];r.value=[e.clientX,t[1]-e.clientY],r.dirty=!0},update:e=>{drag.update_uniform(e)},start:e=>{webgl.is_valid&&(drag.update_uniform(e),pointer.move.forEach((e=>{document.addEventListener(e,drag.update)})))},stop:e=>{webgl.is_valid&&(drag.update_uniform(e),pointer.move.forEach((e=>{document.removeEventListener(e,drag.update)})))}},resize=()=>{if(!webgl.is_valid)return;let e=webgl.uniforms[0].value;webgl.resize();let t=webgl.uniforms[0].value,r=[t[0]/e[0],t[1]/e[1]],a=webgl.uniforms[2];a.value=[a.value[0]*r[0],a.value[1]*r[1]],a.dirty=!0};const SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjUiIGhlaWdodD0iMjMiIHZpZXdCb3g9IjAgMCAyNSAyMyIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0yIDBIMVYxSDJIM1YwSDJaTTUgMEg2SDdWMUg2SDVWMFpNOSAwSDEwSDExSDEySDEzVjFIMTJIMTFIMTBIOVYwWk0xNSAwSDE2SDE3VjFIMTZWMkgxNUgxNFYxSDE1VjBaTTE5IDBIMjBIMjFWMUgyMlYySDIxSDIwVjFIMTlWMFpNMjQgMUgyNVYyVjNWNFY1SDI0VjRWM1YyVjFaTTQgMkgzVjNWNEg0VjNWMlpNMyA2SDRWN1Y4SDNWN1Y2Wk0yNCA3SDI1VjhWOUgyNFY4VjdaTTEyIDlIMTNWMTBIMTJWOVpNMTUgOUgxNFYxMEgxNVY5Wk0zIDEwSDRWMTFWMTJWMTNIM1YxMlYxMVYxMFpNMyAxM1YxNEgyVjEzSDNaTTEyIDExSDEzVjEySDEyVjExWk0xNSAxMUgxNFYxMkgxNVYxMVpNMjQgMTFIMjVWMTJWMTNWMTRIMjRWMTNWMTJWMTFaTTMgMTZIMlYxN0gxVjE4VjE5VjIwSDBWMjFIMUgyVjIwVjE5VjE4VjE3SDNWMTZaTTI0IDE2SDI1VjE3VjE4VjE5SDI0VjE4VjE3VjE2Wk0yMyAyMVYyMFYxOUgyNFYyMFYyMUgyM1pNMjMgMjJWMjFIMjJWMjJWMjNIMjNIMjRWMjJIMjNaTTUgMjBINFYyMUg1SDZWMjJIN0g4SDlWMjFIOEg3SDZWMjBINVpNMTIgMjFIMTFWMjJIMTJIMTNIMTRWMjFIMTNIMTJaTTE2IDIxSDE3SDE4SDE5SDIwVjIySDE5SDE4SDE3SDE2VjIxWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cg==",appendSignature=()=>{const e=document.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",body.appendChild(e)};if(webgl)start_shader(frag_piece),resize(),pointer.start.forEach((e=>{document.addEventListener(e,drag.start)})),pointer.end.forEach((e=>{document.addEventListener(e,drag.stop)})),window.addEventListener("resize",resize),appendSignature();else{const e=document.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="NOT SUPPORTED",document.body.append(e)}'
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
        return 'Mania';
    }

    function symbol() public view virtual returns (string memory) {
        return 'M';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Mania', '</title>'

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
