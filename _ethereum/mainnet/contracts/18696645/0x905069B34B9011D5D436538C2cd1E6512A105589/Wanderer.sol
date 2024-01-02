// ,.   ,   ,.         .                 
// `|  /|  / ,-. ,-. ,-| ,-. ,-. ,-. ,-. 
//  | / | /  ,-| | | | | |-' |   |-' |   
//  `'  `'   `-^ ' ' `-' `-' '   `-' '  
//
// SPDX-License-Identifier: MIT
// Copyright Han, 2023

pragma solidity ^0.8.21;

contract Wanderer {
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
        'You are.' '\n'
    );

    string public constant CORE = (
        'const DIRECTIVES=["#ifdef GL_ES","precision highp float;","#endif","#define AA 2","#define R(a)mat2(cos(a),sin(a),-sin(a),cos(a))"].map((e=>`${e}${String.fromCharCode(10)}`)).join("");let frag_piece=`${DIRECTIVES}uniform vec2 u_resolution,u_mouse;uniform float u_time;float v,r;vec3 t(vec3 v){v=vec3(dot(v,vec3(127.1,311.7,74.7)),dot(v,vec3(269.5,183.3,246.1)),dot(v,vec3(113.5,271.9,124.6)));return-1.+2.*fract(sin(v)*43758.5453123);}vec3 f(vec3 v){return clamp(v*(2.51*v+.03)/(v*(2.43*v+.59)+.14),0.,1.);}float n(vec3 v){return fract(sin(dot(v,vec3(12.9898,78.233,128.852)))*43758.5453)*2.-1.;}float e(vec3 v){float f=(v.x+v.y+v.z)*(1./3.),r,i,s,x,y,d,A,z,a,p,u,c,m,e,g,l,C,E,t,b,B,k;int G=int(floor(v.x+f)),D=int(floor(v.y+f)),F=int(floor(v.z+f)),H,I,J,K,L,M;r=1./6.;i=float(G+D+F)*r;s=float(G)-i;x=float(D)-i;y=float(F)-i;s=v.x-s;x=v.y-x;y=v.z-y;M=s>=x?x>=y?(H=1,I=0,J=0,K=1,L=1,0):s>=y?(H=1,I=0,J=0,K=1,L=0,1):(H=0,I=0,J=1,K=1,L=0,1):x<y?(H=0,I=0,J=1,K=0,L=1,1):s<y?(H=0,I=1,J=0,K=0,L=1,1):(H=0,I=1,J=0,K=1,L=1,0);d=s-float(H)+r;A=x-float(I)+r;z=y-float(J)+r;a=s-float(K)+2.*r;p=x-float(L)+2.*r;u=y-float(M)+2.*r;c=s-1.+3.*r;m=x-1.+3.*r;e=y-1.+3.*r;vec3 h=vec3(G,D,F),O=vec3(G+H,D+I,F+J),P=vec3(G+K,D+L,F+M),Q=vec3(G+1,D+1,F+1),S=normalize(vec3(n(h),n(h*2.01),n(h*2.02))),T=normalize(vec3(n(O),n(O*2.01),n(O*2.02))),U=normalize(vec3(n(P),n(P*2.01),n(P*2.02))),V=normalize(vec3(n(Q),n(Q*2.01),n(Q*2.02)));g=0.;l=0.;C=0.;E=0.;t=.5-s*s-x*x-y*y;if(t>=0.)t*=t,g=t*t*dot(S,vec3(s,x,y));b=.5-d*d-A*A-z*z;if(b>=0.)b*=b,l=b*b*dot(T,vec3(d,A,z));B=.5-a*a-p*p-u*u;if(B>=0.)B*=B,C=B*B*dot(U,vec3(a,p,u));k=.5-c*c-m*m-e*e;if(k>=0.)k*=k,E=k*k*dot(V,vec3(c,m,e));return 96.*(g+l+C+E);}float t(vec2 v){vec3 r=fract(vec3(v.xyx)*.13);r+=dot(r,r.yzx+3.333);return fract((r.x+r.y)*r.z);}float p(vec2 v){vec2 x=floor(v),y=fract(v),r;float f=t(x),L=t(x+vec2(1,0)),n=t(x+vec2(0,1)),s=t(x+vec2(1));r=y*y*(3.-2.*y);return mix(f,L,r.x)+(n-f)*r.y*(1.-r.x)+(s-L)*r.x*r.y;}float m(vec2 v){float r=-7.,y=1.7;vec2 f=vec2(1.5,5),s=vec2(.13,5),L=vec2(-u_time)*-s.x;L.x*=-1.;mat2 m=mat2(cos(.5),sin(.5),-sin(.5),cos(.5));for(int x=0;x<2;++x)r+=y*p(v),v=m*v*.5+f+L*s.y,y*=2.8;return r;}vec2 s(vec3 v){float y=0.,x=1e2,r=v.y+1.,L=m(v.xz*1.5);r+=L*.125;if(x>r)x=r*.8,y=2.;return vec2(x,y);}vec3 c(vec3 v){vec2 r=vec2(.002,0);float x=s(v).x;return normalize(vec3(x-s(v-r.xyy).x,x-s(v-r.yxy).x,x-s(v-r.yyx).x));}vec2 c(vec3 v,vec3 f){float r=0.;vec2 x;for(int y=0;y<128;y++){vec3 L=v+f*r;x=s(L);r+=x.x;if(r>1e2||abs(x.x)<.001)break;}r=min(r,1e2);return vec2(r,x.y);}float e(vec3 v,vec3 f){float x=1.,L=(.8-v.y)/f.y,r,y;if(L>0.)x=min(x,L);r=1.;y=.01;for(int i=0;i<16;i++){float d=s(v+f*y).x,z=clamp(.5*d/y,0.,1.);r=min(r,z*z*(3.-2.*z));y+=clamp(d,.002,.05);if(r<.005||y>x)break;}return clamp(r,0.,1.);}vec4 f(vec3 v,vec3 x){vec3 y=c(v),r=vec3(2,5,-10),L;r=normalize(v-r);float f=clamp(dot(r,y),0.,1.),n=clamp(1.+dot(x,y),0.,1.),s=clamp(dot(reflect(-r,y),-x),0.,1.),i;L=mix(vec3(.6235),vec3(1),f)*2.;L+=vec3(1)*pow(n,7.);L+=vec3(1)*pow(s,2.)*.75;i=e(v,v+vec3(0));L=mix(L*vec3(.6941),L,i);return vec4(L,n);}vec4 m(vec2 x,vec2 r){v=fract(v);vec2 L=(x-.5*r)/r.y,y;vec3 s=vec3(0,3,-10),n=normalize(vec3(0)-s),z=normalize(vec3(n.z,0,-n.x)),F=normalize(L.x*z+L.y*cross(n,z)+n/.43),i,a;y=c(s,F);i=s+F*y.x;a=vec3(0);if(y.x<50.){a=f(i,F).xyz;if(y.y==1.)a=mix(vec3(.0667,.1176,.1686),vec3(.4039),pow(a,vec3(3)));}float d=e(vec3(L*5e2,i.z))*.5+.5,A=smoothstep(.15,.1,d),u;d=(d+A)*.1;d=clamp(d,0.,.5);u=smoothstep(0.,15.,length(i));a=mix(a,mix(vec3(1),vec3(.4431,.4235,.451),L.y+.5)*1.75,u);a=f(a);return vec4(a,u);}vec4 n(vec2 x,vec2 y){vec4 f=vec4(0,0,0,1);for(int L=0;L<AA;L++)for(int i=0;i<AA;i++){float s=u_time-.05*(.5+.5*sin(x.x*147.)*sin(x.y*131.)+float(L*AA+i))/float(AA*AA);v=s/0.;r=2.*acos(-1.)*v;f+=m(x+vec2(i,L)/float(AA),y);}f/=float(AA*AA);return f;}void main(){vec4 v=n(gl_FragCoord.xy,u_resolution);gl_FragColor=vec4(v.xyz+fract(555.*sin(777.*t(gl_FragCoord.xy.xyy)))/256.,1);}`,vert_shader="attribute vec2 p;void main(){gl_Position=vec4(p,1.0,1.0);}",w=window,d=document,device_ratio=window.devicePixelRatio,pixel=new Uint8Array(4),is_mobile=/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent),canvas=d.querySelector("canvas");if(document.body.style.touchAction="none",document.body.style.userSelect="none",!canvas){canvas=d.createElement("canvas"),canvas.style.display="block";var body=d.body;body||(body=d.createElement("body")),body.appendChild(canvas),d.documentElement.appendChild(body)}let webglOptions={};is_mobile||(webglOptions={powerPreference:"high-performance"});let webgl=canvas.getContext("webgl",webglOptions);webgl.program=null,webgl.uniform=(e,r)=>{let t=Array.isArray(r)?r.length-1:0,M=[["uniform1f",0,"float"],["uniform2fv",[0,0],"vec2"]],i={};return i.name=e,i.type=M[t][0],i.value=r||M[t][1],i.inner_type=M[t][2],i.location="",i.dirty=!1,i},webgl.uniforms=[["u_resolution",[0,0]],["u_time",.001*performance.now()],["u_mouse",[0,0]]],webgl.uniforms.forEach(((e,r)=>webgl.uniforms[r]=webgl.uniform(e[0],e[1]))),webgl.create_shader=(e,r,t)=>{let M=e.createShader(r);return webgl.shaderSource(M,t),webgl.compileShader(M),M},webgl.resize=()=>{canvas.width=w.innerWidth*device_ratio,canvas.height=w.innerHeight*device_ratio,canvas.style.width="100%",canvas.style.height="100%";let e=webgl.uniforms[0];e.value=[canvas.width,canvas.height],e.dirty=!0},webgl.render=()=>{webgl.viewport(0,0,canvas.width,canvas.height);let e=webgl.uniforms[1];e.value=.001*performance.now(),e.dirty=!0;let r=webgl.uniforms.filter((e=>1==e.dirty));for(let e in r)webgl[r[e].type](r[e].location,r[e].value),r[e].dirty=!1;webgl.drawArrays(webgl.TRIANGLE_STRIP,0,4),webgl.readPixels(0,0,1,1,webgl.RGBA,webgl.UNSIGNED_BYTE,pixel)},webgl.is_valid=()=>null!=webgl.program,webgl.start_update=()=>{webgl.render(),webgl.frame=requestAnimationFrame(webgl.start_update)},webgl.stop_update=()=>{webgl.frame&&cancelAnimationFrame(webgl.frame)},webgl.change_aa=e=>{frag_piece=frag_piece.replace("#define AA 2",`#define AA ${e}`)};let pointer,load_shader=(e,r)=>{null==r&&(r=vert_shader);let t=webgl;t.stop_update(),t.deleteProgram(t.program),t.program=t.createProgram();const M=webgl.create_shader(t,t.VERTEX_SHADER,r),i=webgl.create_shader(t,t.FRAGMENT_SHADER,e);t.attachShader(t.program,M),t.attachShader(t.program,i),t.linkProgram(t.program);for(let e in webgl.uniforms){let r=webgl.uniforms[e];r.location=t.getUniformLocation(t.program,r.name),r.dirty=!0}let a=Float32Array.of(-1,1,-1,-1,1,1,1,-1),o=t.createBuffer(),n=t.getAttribLocation(t.program,"p");t.bindBuffer(t.ARRAY_BUFFER,o),t.bufferData(t.ARRAY_BUFFER,a,t.STATIC_DRAW),t.enableVertexAttribArray(n),t.vertexAttribPointer(n,2,t.FLOAT,!1,0,0),t.useProgram(t.program),t.resize()},start_shader=(e,r)=>{is_mobile&&webgl.change_aa(1),load_shader(e,r),webgl.start_update()};pointer=w.PointerEvent?{start:["pointerdown"],move:["pointermove"],end:["pointerup"]}:{start:["mousedown","touchstart"],move:["mousemove","touchmove"],end:["mouseup","touchend"]};let drag={update_uniform:e=>{let r=webgl.uniforms[0].value,t=webgl.uniforms[2];t.value=[e.clientX,r[1]-e.clientY],t.dirty=!0},update:e=>{drag.update_uniform(e)},start:e=>{webgl.is_valid&&(drag.update_uniform(e),pointer.move.forEach((e=>{document.addEventListener(e,drag.update)})))},stop:e=>{webgl.is_valid&&(drag.update_uniform(e),pointer.move.forEach((e=>{document.removeEventListener(e,drag.update)})))}},resize=()=>{if(!webgl.is_valid)return;let e=webgl.uniforms[0].value;webgl.resize();let r=webgl.uniforms[0].value,t=[r[0]/e[0],r[1]/e[1]],M=webgl.uniforms[2];M.value=[M.value[0]*t[0],M.value[1]*t[1]],M.dirty=!0};const SIGNATURE_SVG="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjIiIGhlaWdodD0iMjIiIHZpZXdCb3g9IjAgMCAyMiAyMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBjbGlwLXJ1bGU9ImV2ZW5vZGQiIGQ9Ik0yMS42Mzg2IDIwLjU0NTZDMjEuNjUxNiAyMC40Njc3IDIxLjY1MDUgMjAuMzg2IDIxLjYzNTQgMjAuMzA1MUMyMS4xMTEzIDE3LjYwMDggMjEuMDc5OSAxNC44NTYxIDIxLjA0ODIgMTIuMTFDMjEuMDI1MyAxMC4xMTYyIDIxLjAwMjYgOC4xMjIwMSAyMC43OTEyIDYuMTQyNjVDMjAuNjQ4MiA0LjgwMzkxIDIwLjQyNDggMy40NzQwMSAyMC4wNjc0IDIuMTczMzNDMjAuMDAyNyAxLjk0MDUxIDE5Ljc3MjYgMS43NTkxMyAxOS41Mjg5IDEuNzYxNkMxNy45NjQ0IDEuNzg3NjYgMTYuNDc0MiAxLjM0ODgxIDE0Ljk4NDQgMC45MTAzMjFDMTQuMTgzNSAwLjY3NDM0NiAxMy4zODI2IDAuNDM4MzcxIDEyLjU3MDQgMC4yNzQ5NDlDMTAuMDgwNCAtMC4yMjcyOTIgNy41NjM1IDAuMDU4Njk2MyA1LjA2Njc0IDAuMzQyMjE5TDUuMDQ0NTYgMC4zNDQzMzJDNC4zNzM5NiAwLjQyMDQwOSAzLjcwMzAxIDAuNDk0MDE5IDMuMDMwNjYgMC41NDg5NjNDMi4yNzYyNCAwLjYxMDI0NSAxLjUyMDQyIDAuNjQ4MjgzIDAuNzYyMTI2IDAuNjM5ODNDMC4zNjAyNjQgMC42MzUyNTEgMC4xNzcxMTggMC45OTgwMiAwLjIyMzk2MiAxLjM0NzRDMC45MTYzOTEgNi40MzM1NyAwLjg0NDg5NSAxMS42MDc0IDAuNDMzODc0IDE2LjcxNEMwLjMxNzY0NyAxOC4xNjQ4IDAuMTcwNDI2IDE5LjYxNTUgMC4wMDI3Nzc3MyAyMS4wNjE2Qy0wLjAzMzE0NjkgMjEuMzYzOCAwLjI4NjMwMSAyMS42MjEzIDAuNTYxMDE5IDIxLjYyMTNMOC4xMjQyMSAyMS42MjY1QzExLjAzMzggMjEuNjI4MyAxMy45NDMzIDIxLjYzMDEgMTYuODUyOCAyMS42MzI1QzE4LjM4MzEgMjEuNjM5MSAxOS45MjIyIDIxLjYzOTEgMjEuNDYxMyAyMS42MzkxQzIyLjExMzggMjEuNjM5MSAyMi4xNzQ0IDIwLjcxMyAyMS42Mzg2IDIwLjU0NTZaTTIwLjU0MDggMjAuNTE5MUMyMC4yOTM1IDE5LjIxODggMjAuMTQ2IDE3LjkwMTMgMjAuMDYyOSAxNi41Nzk4QzE5Ljk3MDkgMTUuMTI1OSAxOS45NTM2IDEzLjY2MjIgMTkuOTM2MyAxMi4xOTc3QzE5Ljg5OTMgOS4wNjQxNyAxOS44NjI0IDUuOTI3MSAxOS4wOTU2IDIuODc5NDlDMTcuODc5NSAyLjg0MDAzIDE2LjY4MzggMi41NTk2OCAxNS41MTY5IDIuMjI5MzJDMTQuMzU3NSAxLjkwMDM3IDEzLjIyNzMgMS41MzA5IDEyLjAyMzEgMS4zMDkzN0MxMC44MTkzIDEuMDg3NDggOS41ODE2MiAxLjA3NjU2IDguMzYxOTYgMS4xNDU5NEM3LjMzIDEuMjAzMzUgNi4zMDIyNyAxLjMxOTU4IDUuMjc0ODkgMS40MzYxNkMzLjk4MTk2IDEuNTgyNjggMi42ODkwMyAxLjcyOTE5IDEuMzg3NjQgMS43NTc3MkMxLjQ3MDQxIDIuNDIxNjIgMS41NDIyNSAzLjA4NjI0IDEuNjAyNDggMy43NTI2QzEuNjU0OTYgNC4zMzI2OCAxLjY5ODk4IDQuOTEzNDYgMS43MzM4NSA1LjQ5NTY1QzIuMDM1MzQgMTAuNTA0MyAxLjczMjggMTUuNTI3NCAxLjE3NjMyIDIwLjUwNzJDMi41MDc2NCAyMC41MDg3IDMuODM3OTEgMjAuNTA4NyA1LjE2OTU4IDIwLjUwODdDOS4wNjUzMSAyMC41MTE3IDEyLjk2MSAyMC41MTM5IDE2Ljg1NjcgMjAuNTE2NEwyMC41NDA4IDIwLjUxOTFaTTEwLjc0NiAxMi4yMzAxQzEwLjQxOTIgMTIuMjA3OSAxMC4xMzk5IDEyLjE4OTMgMTAuMDE5OCAxMi4yMjk4QzkuNDc0MiAxMi4yNjc0IDkuNTQwMDcgMTEuMjkzNiA5LjU4OTc0IDEwLjU2MjFDOS42MTE1NyAxMC4yMzY2IDkuNjMwMjQgOS45NTkxIDkuNTkwNDQgOS44MzkzNkM5LjU1Mjc1IDkuMjkzNDQgMTAuNTI2MiA5LjM1OTMxIDExLjI1NzggOS40MDg5OEMxMS41ODI4IDkuNDMwODEgMTEuODYwNCA5LjQ0OTgyIDExLjk4MDEgOS40MTAwMkMxMi41MjU3IDkuMzcyMzMgMTIuNDU5OCAxMC4zNDYyIDEyLjQxMDIgMTEuMDc3N0MxMi4zODgzIDExLjQwMzEgMTIuMzY5NyAxMS42ODA3IDEyLjQwOTUgMTEuODAwNEMxMi40NDU0IDEyLjM0NTMgMTEuNDc2NSAxMi4yNzk0IDEwLjc0NiAxMi4yMzAxWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cg==",appendSignature=()=>{const e=document.createElement("img");e.src=SIGNATURE_SVG.trim(),e.style.cssText="width:40px;z-index:50;position:fixed;bottom:20px;right:20px;",body.appendChild(e)};if(webgl)start_shader(frag_piece),resize(),pointer.start.forEach((e=>{document.addEventListener(e,drag.start)})),pointer.end.forEach((e=>{document.addEventListener(e,drag.stop)})),window.addEventListener("resize",resize),appendSignature();else{const e=document.createElement("div");e.style.cssText="align-items:center;background:#969696;color:#fff;display:flex;font-family:monospace;font-size:20px;height:100vh;justify-content:center;left:0;position:fixed;top:0;width:100vw;",e.innerHTML="NOT SUPPORTED",document.body.append(e)}'
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
        return 'Wanderer';
    }

    function symbol() public view virtual returns (string memory) {
        return 'W';
    }

    function artpiece() public view virtual returns (string memory) {
        return string.concat(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', 'Wanderer', '</title>'

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
