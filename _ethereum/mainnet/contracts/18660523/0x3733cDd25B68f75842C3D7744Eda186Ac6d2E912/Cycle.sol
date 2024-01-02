// ┏┓   ┓  
// ┃ ┓┏┏┃┏┓
// ┗┛┗┫┗┗┗ 
//    ┛    
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Cycle {
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
        'Again and again.' '\n'
    );

    string public constant CORE = (
        'const DIRECTIVES=["#ifdef GL_ES","precision highp float;","#endif","#define AA 2","#define R(a)mat2(cos(a),sin(a),-sin(a),cos(a))"].map((e=>`${e}${String.fromCharCode(10)}`)).join("");let frag_piece=`${DIRECTIVES}uniform vec2 u_resolution,u_mouse;uniform float u_time;float v;vec3 t(vec3 v){v=vec3(dot(v,vec3(127.1,311.7,74.7)),dot(v,vec3(269.5,183.3,246.1)),dot(v,vec3(113.5,271.9,124.6)));return-1.+2.*fract(sin(v)*43758.5453123);}vec3 s(vec3 v){return clamp(v*(2.51*v+.03)/(v*(2.43*v+.59)+.14),0.,1.);}float n(vec3 v){return dot(vec2(sqrt(1.)*.5,.5),vec2(length(v.xz),v.y));}float f(float v){return v==0.||v==1.?v:(v*=1.)<1e2?.5*pow(2.,10.*(v-5.)):.5*(-pow(2.,-10.*(v-5.))+2.);}vec2 p(vec3 m){float y=0.,a=1e2,A=v,r=fract(A),x,d,s;r=f(r);x=acos(-1.)*.5;d=mod(A,2.);d=floor(d);d*=x;vec3 i=m;i.xy*=R(mix(d,x+d,r));i.y=abs(i.y);i.xy*=R(-acos(-1.));s=n(i);if(a>s)a=s,y=1.;return vec2(a,y);}vec3 m(vec3 v){vec2 d=vec2(.002,0);float f=p(v).x;return normalize(vec3(f-p(v-d.xyy).x,f-p(v-d.yxy).x,f-p(v-d.yyx).x));}vec2 f(vec3 v,vec3 y){float f=0.;vec2 d;for(int r=0;r<128;r++){vec3 a=v+y*f;d=p(a);f+=d.x;if(f>1e2||abs(d.x)<.001)break;}f=min(f,1e2);return vec2(f,d.y);}vec4 m(vec3 d,vec3 a){float y=v,r=f(fract(y)),s=2.*acos(-1.)*.5,A=mod(y,20.),x,i;A=floor(A);A*=s;vec3 n=d,u,p,z;n.xy*=R(mix(A,s-A,r));n.xy*=R(-acos(-1.));d=n;u=m(d);p=vec3(10,10,0);p.zx*=R(2.*acos(-1.)*v*.5);p.xy*=R(2.*acos(-1.)*v*2.);p.yz*=R(2.*acos(-1.)*v);p=normalize(d-p);x=clamp(dot(p,u),0.,1.);i=clamp(1.+dot(a,u),0.,1.);z=mix(vec3(.25),vec3(1),x);z+=vec3(1)*pow(i,5.)*.25;return vec4(z,i);}vec4 f(vec2 v,vec2 d,float y){vec2 a=(v-.5*d)/d.y,i;vec3 A=vec3(0,0,-10),p=normalize(vec3(0)-A),x=normalize(vec3(p.z,0,-p.x)),r=normalize(a.x*x+a.y*cross(p,x)+p/.37),u,z;i=f(A,r);u=A+r*i.x;z=vec3(0);if(i.x<50.)z=m(u,r).xyz;float n=smoothstep(0.,11.5,length(u));z=mix(z,vec3(.93),n);z=s(z);return vec4(z,n);}float d(float v){vec3 d=fract(vec3(v)*443.8975);d+=dot(d,d.yzx+19.19);return fract((d.x+d.y)*d.z);}float r(float v){float a=floor(v);return mix(d(a),d(a+1.),smoothstep(0.,1.,fract(v)));}float e(float v){return(v-=1.)*v*v+1.;}vec4 d(vec2 d,vec2 y){vec4 i=vec4(0,0,0,1);float a=.5+.5*sin(d.x*147.)*sin(d.y*131.),A=u_time/4.,x=e(abs(fract(A*.5+.5)*2.-1.))*step(mod(A*.5,2.),1.),z,p;x=step(mod(A*.5,2.),1.);z=r(u_time*2.);z=smoothstep(.1,2.,pow(z,.2));p=.25*z*x;for(int u=0;u<AA;u++)for(int n=0;n<AA;n++){float m=u_time-.125*(float(u*AA+n)+a)/float(AA*AA);vec2 s=d+vec2(n,u)/float(AA);v=(m-p)/4.;i.x+=f(s,y,-1.).x;v=m/4.;i.y+=f(s,y,0.).y;v=(m+p)/4.;i.z+=f(s,y,1.).z;}i/=float(AA*AA);return i;}void main(){vec4 v=d(gl_FragCoord.xy,u_resolution);gl_FragColor=vec4(v.xyz+fract(555.*sin(77.*t(gl_FragCoord.xy.xyy)))/256.,1);}`,vert_shader="attribute vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}",w=window,d=document,device_ratio=window.devicePixelRatio,pixel=new Uint8Array(4),is_mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),canvas=d.querySelector("canvas");if(document.body.style.touchAction="none",document.body.style.userSelect="none",!canvas){canvas=d.createElement("canvas"),canvas.style.display="block";var body=d.body;body||(body=d.createElement("body")),body.appendChild(canvas),d.documentElement.appendChild(body)}let webglOptions={};is_mobile||(webglOptions={powerPreference:"high-performance"});let webgl=canvas.getContext("webgl",webglOptions);webgl.program=null,webgl.uniform=(e,t)=>{let r=Array.isArray(t)?t.length-1:0,a=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],o={};return o.name=e,o.type=a[r][0],o.value=t||a[r][1],o.inner_type=a[r][2],o.location="",o.dirty=!1,o},webgl.uniforms=[["u_resolution",[0,0]],["u_time",.001*performance.now()],["u_mouse",[0,0]]],webgl.uniforms.forEach(((e,t)=>webgl.uniforms[t]=webgl.uniform(e[0],e[1]))),webgl.create_shader=(e,t,r)=>{let a=e.createShader(t);return webgl.shaderSource(a,r),webgl.compileShader(a),a},webgl.resize=()=>{canvas.width=w.innerWidth*device_ratio,canvas.height=w.innerHeight*device_ratio,canvas.style.width="100%",canvas.style.height="100%";let e=webgl.uniforms[0];e.value=[canvas.width,canvas.height],e.dirty=!0},webgl.render=()=>{webgl.viewport(0,0,canvas.width,canvas.height);let e=webgl.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let t=webgl.uniforms.filter((e=>1==e.dirty));for(let e in t)webgl[t[e].type](t[e].location,t[e].value),t[e].dirty=!1;webgl.drawArrays(webgl.TRIANGLE_STRIP,0,4),webgl.readPixels(0,0,1,1,webgl.RGBA,webgl.UNSIGNED_BYTE,pixel)},webgl.is_valid=()=>null!=webgl.program,webgl.start_update=()=>{webgl.render(),webgl.frame=requestAnimationFrame(webgl.start_update)},webgl.stop_update=()=>{webgl.frame&&cancelAnimationFrame(webgl.frame)},webgl.change_aa=e=>{frag_piece=frag_piece.replace("#define AA 2",`#define AA ${e}`)};let pointer,load_shader=(e,t)=>{null==t&&(t=vert_shader);let r=webgl;r.stop_update(),r.deleteProgram(r.program),r.program=r.createProgram();const a=webgl.create_shader(r,r.VERTEX_SHADER,t),o=webgl.create_shader(r,r.FRAGMENT_SHADER,e);r.attachShader(r.program,a),r.attachShader(r.program,o),r.linkProgram(r.program);for(let e in webgl.uniforms){let t=webgl.uniforms[e];t.location=r.getUniformLocation(r.program,t.name),t.dirty=!0}let i=Float32Array.of(-1,1,-1,-1,1,1,1,-1),n=r.createBuffer(),d=r.getAttribLocation(r.program,"p");r.bindBuffer(r.ARRAY_BUFFER,n),r.bufferData(r.ARRAY_BUFFER,i,r.STATIC_DRAW),r.enableVertexAttribArray(d),r.vertexAttribPointer(d,2,r.FLOAT,!1,0,0),r.useProgram(r.program),r.resize()},start_shader=(e,t)=>{is_mobile&&webgl.change_aa(1),load_shader(e,t),webgl.start_update()};pointer=w.PointerEvent?{start:["pointerdown"],move:["pointermove"],end:["pointerup"]}:{start:["mousedown","touchstart"],move:["mousemove","touchmove"],end:["mouseup","touchend"]};let drag={update_uniform:e=>{let t=webgl.uniforms[0].value,r=webgl.uniforms[2];r.value=[e.clientX,t[1]-e.clientY],r.dirty=!0},update:e=>{drag.update_uniform(e)},start:e=>{webgl.is_valid&&(drag.update_uniform(e),pointer.move.forEach((e=>{document.addEventListener(e,drag.update)})))},stop:e=>{webgl.is_valid&&(drag.update_uniform(e),pointer.move.forEach((e=>{document.removeEventListener(e,drag.update)})))}},resize=()=>{if(!webgl.is_valid)return;let e=webgl.uniforms[0].value;webgl.resize();let t=webgl.uniforms[0].value,r=[t[0]/e[0],t[1]/e[1]],a=webgl.uniforms[2];a.value=[a.value[0]*r[0],a.value[1]*r[1]],a.dirty=!0};const SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjYiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNiAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0yNC43MzI1IDBIMjUuNDkxMVYxNy4yNEgyNC43MzI1VjBaTTYuMzE1NjkgMS40OTExSDI0LjMzOTZWMi4zMjgzM0g2LjMxNTY5VjEuNDkxMVpNNy4yNzM2OSAzLjY0NDI0SDYuNTY1MVYxOS4yOTMxSDBWMjAuMTA3OUg2LjU2NTFWMjMuMTg1SDcuMjczNjlWMjAuMTA3OUgyNlYxOS4yOTMxSDcuMjczNjlWMy42NDQyNFpNMTcuNDUwNiAxMi42NzEzSDEzLjk4NjlWOS4wMTYwOEgxNy40NTA2VjExLjg2NjJIMTkuNDU1NlYxMi42NjY2SDE3LjQ1MDZWMTIuNjcxM1pNMTYuNDQ3NyAxMS44NjYySDE0Ljc5MjFWOS44MjEyM0gxNi42NDU1VjExLjg2NjJIMTYuNDQ3N1oiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPgo=",appendSignature=()=>{const e=document.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",body.appendChild(e)};if(webgl)start_shader(frag_piece),resize(),pointer.start.forEach((e=>{document.addEventListener(e,drag.start)})),pointer.end.forEach((e=>{document.addEventListener(e,drag.stop)})),window.addEventListener("resize",resize),appendSignature();else{const e=document.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="NOT SUPPORTED",document.body.append(e)}'
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
        return 'Cycle';
    }

    function symbol() public view virtual returns (string memory) {
        return 'C';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Cycle', '</title>'

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
