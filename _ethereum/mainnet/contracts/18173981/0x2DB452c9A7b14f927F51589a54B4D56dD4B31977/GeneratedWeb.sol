// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./base64.sol";
import "./MerkleProof.sol";
import "./IDelegationRegistry.sol";
import "./IDescriptor.sol";

contract Web is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IDelegationRegistry delegationRegistry = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    struct TokenData {
        string seed;
        string name;
        uint8 color;
        uint8 complexity;
        uint8 coverage;
    }

    string[] public colorOptions = [
        '#FF0000',
        '#FF8000',
        '#FFFF00',
        '#80FF00',
        '#00FF00',
        '#00FF80',
        '#00FFFF',
        '#0080FF',
        '#0000FF',
        '#8000FF',
        '#FF00FF',
        '#FF0080'
    ];

    string[3] public complexityOptions = ['Simple', 'Medium', 'Intricate'];
    string[3] public coverageOptions = ['Thin', 'Medium', 'Full'];

    TokenData[] public tokenData;

    bytes32 public holderMerkleRoot = 0x9c4647684312cdd1cd10365dc25ce3be8aae724cd4654d13d91deda5417d4c25; // 20% discount
    bytes32 public fpMembersMerkleRoot = 0xe79d621b6ce06c4c74de82ba8f7a7e320228f93cde3e368de3d5e268b74e1c2d; // 20% discount
    bytes32 public communitiesMerkleRoot = 0x31605546a4c8b9934eedbb27b9de88bb7121c4bfc1f4b753f1305e6d9885faff; // 15% discount

    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    SalesConfig public config;

    struct SalesConfig {
        uint64 startTime;
        uint64 endTime;
        uint256 startPriceInWei; // 1 eth
        uint256 endPriceInWei; // .1 eth
        address payable fundsRecipient;
    }

    mapping(uint256 => bool) public tokenIsMinted;
    uint256 private nextAvailableRandomId;
    uint256 public supplyCount;
    uint256 public maxSupply = 1000;

    /// @dev this work is entirely on chain but we'll serve static images as thumbnails
    string public ipfsHash = 'bafybeib2zkka7bqpuucbbirwu2g6vjen66buetxovijrafsh7wuhdjvdbu';
    string public externalUrl = 'https://web.leegte.org/?id=';

    /// @dev optional descriptor in case we need to adjust on chain elements 
    address public descriptor;

    event NewMint(address indexed _owner, uint256 indexed _tokenId);

    constructor()
      ERC721("Web", "WEB")
    {
        config.startTime = uint64(1695225600);
        config.endTime = uint64(1695225600 + 3600);
        config.startPriceInWei = 1000000000000000000; // 1 eth
        config.endPriceInWei = 100000000000000000; // .1 eth
        config.fundsRecipient = payable(0x9220e3df5f4A8439B7DecfbB9f39BE98c188F5f2);
        
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 elapsedTime = ((block.timestamp - config.startTime) / 10 ) * 10;
        
        uint256 duration = config.endTime - config.startTime;
        uint256 halflife = 950; // adjust this to adjust speed of decay

        if (block.timestamp < config.startTime) {
            return config.startPriceInWei;
        }

        if (elapsedTime >= duration) {
            return config.endPriceInWei;
        }

        // h/t artblocks for exponential decaying price math
        uint256 decayedPrice = config.startPriceInWei;
        // Divide by two (via bit-shifting) for the number of entirely completed
        // half-lives that have elapsed since auction start time.
        decayedPrice >>= elapsedTime / halflife;
        // Perform a linear interpolation between partial half-life points, to
        // approximate the current place on a perfect exponential decay curve.
        decayedPrice -= (decayedPrice * (elapsedTime % halflife)) / halflife / 2;
        if (decayedPrice < config.endPriceInWei) {
            // Price may not decay below stay `basePrice`.
            return config.endPriceInWei;
        }
        decayedPrice = (decayedPrice / 1000000000000000) * 1000000000000000;
        return decayedPrice;
    }

    function _mintWithChecks(uint256 tokenId, bytes32[] calldata merkleProof, address vault) internal {
        require(block.timestamp >= config.startTime && block.timestamp <= config.endTime, "Sale inactive");
        uint256 currentPrice = getCurrentPrice();

        if (merkleProof.length > 0) {
            // check delegate.cash to see if this sender is a delegate for a vault
            bool senderIsVaultDelegate = delegationRegistry.checkDelegateForAll(msg.sender, vault);

            address addressToCheck = senderIsVaultDelegate ? vault : msg.sender;

            // check address against merkle roots for various allowlists and then apply appropriate discount
            bool isCommunity = checkMerkleProof(merkleProof, addressToCheck, communitiesMerkleRoot);
            bool isHolder = checkMerkleProof(merkleProof, addressToCheck, holderMerkleRoot);
            bool isFpMember = checkMerkleProof(merkleProof, addressToCheck, fpMembersMerkleRoot);

            if (isHolder || isFpMember) {
                currentPrice = (currentPrice * 80) / 100; // 20% off
            } else if (isCommunity) {
                currentPrice = (currentPrice * 85) / 100; // 15% off
            }
        }

        require(msg.value >= currentPrice, "Not enough ether");

        tokenIsMinted[tokenId] = true;
        supplyCount++;

        _safeMint(msg.sender, tokenId);
        emit NewMint(msg.sender, tokenId);
    }

    function mintSpecific(uint256 tokenId, bytes32[] calldata merkleProof, address vault) external payable nonReentrant {
        require(tokenId < maxSupply, "Invalid token requested");
        require(!_exists(tokenId), "Token already minted!");

        _mintWithChecks(tokenId, merkleProof, vault);
    }

    function mintRandom(bytes32[] calldata merkleProof, address vault) external payable nonReentrant {
        require(supplyCount < 1000, "All tokens minted");
        uint256 nextAvailable = this._findAvailable(nextAvailableRandomId);
 
        nextAvailableRandomId = nextAvailable + 1;

        _mintWithChecks(nextAvailable, merkleProof, vault);
    }

    /// @dev if the one requested is already minted, try the next one. this can
    /// run out of gas in cases where few people mintRandom and all mintSpecific mints
    /// are consolidated in specific regions (highly unlikely)
    function _findAvailable(uint256 index) public view returns (uint256) {
        if (tokenIsMinted[index] == true) {
            return _findAvailable(index + 1);
        } else {
            return index;
        }
    }

    string public templateA = '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body><script>let e;var t,n="undefined"!=typeof globalThis?globalThis:"undefined"!=typeof self?self:"undefined"!=typeof window?window:"undefined"!=typeof global?global:{};function i(e){return e&&e.__esModule?e.default:e}var r={};r=\'html,body,div,span,applet,object,iframe,h1,h2,h3,h4,h5,h6,p,blockquote,pre,a,abbr,acronym,address,big,cite,code,del,dfn,em,img,ins,kbd,q,s,samp,small,strike,strong,sub,sup,tt,var,b,u,i,center,dl,dt,dd,ol,ul,li,fieldset,form,label,legend,table,caption,tbody,tfoot,thead,tr,th,td,article,aside,canvas,details,embed,figure,figcaption,footer,header,hgroup,menu,nav,output,ruby,section,summary,time,mark,audio,video{font-size:100%;font:inherit;vertical-align:baseline;border:0;margin:0;padding:0}article,aside,details,figcaption,figure,footer,header,hgroup,menu,nav,section{display:block}body{line-height:1}ol,ul{list-style:none}blockquote,q{quotes:none}blockquote:before,blockquote:after,q:before,q:after{content:"";content:none}table{border-collapse:collapse;border-spacing:0}\';var o={};o="html,body{width:100%;height:100%;margin:0;padding:0}.container{width:100%;height:100%;display:flex;position:relative}.element{box-sizing:border-box;flex-grow:1;flex-shrink:1;min-width:0;min-height:0;display:flex}input,button{box-sizing:border-box;max-width:100%}select{width:100%}";var a={init:e=>{var t,n,i,r;e+="";let o=function(e){let t=1779033703,n=3144134277,i=1013904242,r=2773480762;for(let o=0,a;o<e.length;o++)t=n^Math.imul(t^(a=e.charCodeAt(o)),597399067),n=i^Math.imul(n^a,2869860233),i=r^Math.imul(i^a,951274213),r=t^Math.imul(r^a,2716044179);return t=Math.imul(i^t>>>18,597399067),n=Math.imul(r^n>>>22,2869860233),i=Math.imul(t^i>>>17,951274213),r=Math.imul(n^r>>>19,2716044179),[(t^n^i^r)>>>0,(n^t)>>>0,(i^t)>>>0,(r^t)>>>0]}(e),a=(t=o[0],n=o[1],i=o[2],r=o[3],function(){t>>>=0,n>>>=0,i>>>=0,r>>>=0;var e=t+n|0;return t=n^n>>>9,n=i+(i<<3)|0,i=i<<21|i>>>11,e=e+(r=r+1|0)|0,i=i+e|0,(e>>>0)/4294967296});return{value:()=>a(),range:(e=0,t=1)=>e+a()*(t-e),rangeInteger:(e=0,t=1)=>e+Math.round(a()*(t-e)),pick:e=>e[Math.floor(a()*e.length)],probability:e=>a()<e,shuffle:e=>{let t=e.length,n,i;for(;0!==t;)i=Math.floor(a()*t),t-=1,n=e[t],e[t]=e[i],e[i]=n;return e}}}};function l(e,t,n){return Math.min(Math.max(e,t),n)}var c={init:e=>{let t={r:e.rangeInteger(0,255),g:e.rangeInteger(0,255),b:e.rangeInteger(0,255)},n={min:0,max:255},i=e.rangeInteger(50);function r(){let r=e.rangeInteger(1,i);t.r+=e.rangeInteger(-r,r),t.r=l(t.r,n.min,n.max),t.g+=e.rangeInteger(-r,r),t.g=l(t.g,n.min,n.max),t.b+=e.rangeInteger(-r,r),t.b=l(t.b,n.min,n.max)}return{single:()=>(function(){r();let e={...t};return e})(),set:()=>(r(),{low:{r:l(t.r-30,n.min,n.max),g:l(t.g-30,n.min,n.max),b:l(t.b-30,n.min,n.max)},mid:{r:t.r,g:t.g,b:t.b},high:{r:l(t.r+30,n.min,n.max),g:l(t.g+30,n.min,n.max),b:l(t.b+30,n.min,n.max)}})}},stringify:(e,t=1)=>`rgba(${e.r},${e.g},${e.b}, ${t})`,distanceSquared:(e,t)=>Math.pow(e.r-t.r,2)+Math.pow(e.g-t.g,2)+Math.pow(e.b-t.b,2),rgbToHsv:e=>{let t,n=e.r/255,i=e.g/255,r=e.b/255,o=Math.max(n,i,r),a=Math.min(n,i,r),l=o-a;if(o==a)t=0;else{switch(o){case n:t=(i-r)/l+(i<r?6:0);break;case i:t=(r-n)/l+2;break;case r:t=(n-i)/l+4}t/=6}return{h:t,s:0==o?0:l/o,v:o}}};const s=a.init("JRLxSPRPSxJK"),d="Document".split("");d[0]=" "+d[0].toUpperCase();const g=s.shuffle(function(e){let t=[];return!function n(i){if(1===i)t.push([...e]);else for(let t=0;t<i;t++)n(i-1),function(t,n){let i=e[t];e[t]=e[n],e[n]=i}(i%2?0:t,i-1)}(e.length),t}(d));\nn.oid=\'';
    
    string public templateB = '\',\n[/*@__PURE__*/i(r),/*@__PURE__*/i(o)].forEach(e=>{let t=document.createElement("style");t.innerHTML=e,document.head.appendChild(t)});const m=a.init("0x5cfcf4"),h={MAX_LEVELS:5,MICRO_CLUSTER_PROBABILITY:.05},u={NONE:0,RADIO_BUTTON:1,SELECT:2,INPUT:3,BUTTON:4,IMAGE:5},f=[66,145,239,305,330,380,401,487,516,754,786,791,935],b=Array(1e3).fill(0).map(function(){let e="";for(let t=0;t<16;t++)e+=m.rangeInteger(0,256).toString(16).padStart(2,"0");return e}),p=({generate:e=>{let t=g.slice(0,e).map(e=>e.join(""));return t}}).generate(1e3),y=n.oid||((e=decodeURIComponent((window.location.search.match(RegExp("(?:[?|&]id=)([^&]+)"))||[,""])[1].replace(/\\+/g,"%20"))||null)&&b.includes(e)||(e=b[911],window.history.replaceState({},"",`?id=${e}`)),e),x=(Object.keys(t=function(e){Object.keys(e).forEach(t=>{e[t].color=c.rgbToHsv(e[t].mainColor).h});let t=Object.keys(e).map(t=>e[t].color),n=Math.min(...t),i=Math.max(...t);return Object.keys(e).forEach(t=>{e[t].color=(e[t].color-n)/(i-n)}),e}(function(e){Object.keys(e).forEach(t=>{let n=e[t].elements;e[t].coverage=function(e){let t=0,n=.4*Math.min(1,1-(e.margin-70)/30)+.6;return function e(n,i){if(n.visibility&&1!==n.basis)t+=n.basis*i*n.coverage*(0!==n.alignment?.5:1);else for(let t of(i*=n.basis,n.children))e(t,i)}(e,n),t}(n)});let t=Object.keys(e).reduce((t,n)=>{let i=e[n].coverage;return t.min=Math.min(t.min,i),t.max=Math.max(t.max,i),t},{min:1/0,max:-1/0});return Object.keys(e).forEach(n=>{e[n].coverage=(e[n].coverage-t.min)/(t.max-t.min),e[n].coverage=Math.max(.001,Math.min(.999,e[n].coverage))}),e}(function(e){Object.keys(e).forEach(t=>{e[t].complexity=e[t].elements.descendants.length});let t=Object.keys(e).reduce((t,n)=>{let i=e[n].complexity;return t.min=Math.min(t.min,i),t.max=Math.max(t.max,i),t},{min:1/0,max:-1/0});return Object.keys(e).forEach(n=>{e[n].complexity=Math.pow((e[n].complexity-t.min)/(t.max-t.min),.5),e[n].coverage=Math.max(.001,Math.min(.999,e[n].coverage))}),e}(b.reduce((e,t)=>(e[t]=function(e){let t=a.init(e),n=c.init(t),i=t.value(),r={margin:{value:i>.5?i:0,min:0,max:10},variance:{value:t.value(),min:0,max:1},fragmentation:{value:t.value(),min:2,max:5},distribution:{value:t.value(),min:0,max:1},padding:{value:i>.5?t.value():0,min:0,max:.05},alignment:{value:t.value(),min:0,max:1},filtering:{value:t.value(),min:0,max:1},raise:{value:t.value(),min:0,max:3},shadow:{value:t.value(),min:0,max:1},coverage:{value:t.value(),min:.5,max:1}},o=function e(i,r,o=!1){var a,l,c;if(r>=(o?h.MAX_LEVELS+1:t.rangeInteger(3,h.MAX_LEVELS)))return;let g=[],m=r===Math.floor((l=s((a=i.raise).value,0),c=a.min,l*(a.max+1-c)+c)),u=t.rangeInteger(o?1:0,8-r);0===r&&0===u&&(u=t.rangeInteger(1,i.fragmentation.max));let f=r===h.MAX_LEVELS-1||0===u,b=t.value()*r>2*t.value();for(let n=0;n<u;n++){let n=e(i,r+1,o||t.probability(h.MICRO_CLUSTER_PROBABILITY));n&&g.push(n)}let p=d(i.distribution,i.variance.value),y=Array(u).fill(0).map(()=>t.range(0,1)),x=y.reduce((e,t)=>e+t,0);y=y.map(e=>e/x).map(e=>e*p+1/u*(1-p)),g.forEach((e,t)=>{e.basis=y[t]});let v=[,,,,].fill(0).map(()=>d(i.padding,i.variance.value)),M=b?t.rangeInteger(1,3):0,k=!0;k=!!o||(r<3?!t.probability(d(i.filtering,i.variance.value)):t.probability(.2*r));let w=m?d(i.shadow,1):0,E=m?t.rangeInteger(1,5):0,I=m?d(i.coverage,1):1,O=f&&!o?t.rangeInteger(0,5):0,$=n.set(),T=n.set(),C={background:$.mid,border:{top:r%2==0?$.high:$.low,left:r%2==0?$.high:$.low,bottom:r%2==0?$.low:$.high,right:r%2==0?$.low:$.high},content:T},S={basis:1,margin:0===r?d(i.margin,0):0,padding:v,alignment:M,visibility:k,shadow:w,parent:null,content:O,contentSize:t.value(),contentValue:t.value(),colors:C,zIndex:E,coverage:I,children:g,link:null,descendants:[...g.map(e=>e.descendants),...g].flat()};return g.forEach(e=>{e.parent=S}),S}(r,0);if(!o.descendants.some(e=>e.visibility)){let e=t.pick(o.descendants);e.visibility=!0}if(!o.descendants.some(e=>0!==e.content&&e.visibility)){let e=t.pick(o.descendants);e.content=t.rangeInteger(1,5)}let l={id:e,mainColor:n.set().low,elements:o};return l;function s(e,n){let i=Math.max(0,e-n/2),r=Math.min(1,e+n/2);return t.range(i,r)}function d(e,t){var n,i;return n=s(e.value,t),i=e.min,n*(e.max-i)+i}}(t),e),{}))))).forEach((e,n)=>{t[e].title=p[n]}),Object.keys(t).map(e=>(delete t[e].distance,delete t[e].axis,delete t[e].direction,t[e])).filter(e=>e.id!==y).forEach(e=>{let n=[{axis:"complexity",distance:Math.abs(e.complexity-t[y].complexity)},{axis:"coverage",distance:Math.abs(e.coverage-t[y].coverage)},{axis:"color",distance:Math.sqrt(Math.pow(e.mainColor.r/255-t[y].mainColor.r/255,2)+Math.pow(e.mainColor.g/255-t[y].mainColor.g/255,2)+Math.pow(e.mainColor.b/255-t[y].mainColor.b/255,2))}],i=n.reduce((e,{axis:t,distance:n})=>e+n,0),r=n.sort((e,t)=>e.distance-t.distance)[0].axis,o=e[r]>t[y][r]?"greater":"less";e.distance=i,e.axis=r,e.direction=o}),t),v=function(){let e=document.createElement("div");return e.classList.add("container"),document.body.appendChild(e),e}();x[y].title;const M=[];function k(e,t,n){return Object.values(e).filter(({axis:e,direction:i})=>e===t&&i===n).sort((e,t)=>e.distance-t.distance).map(({id:e})=>e)}const w={complexity:{prev:k(x,"complexity","less"),next:k(x,"complexity","greater")},coverage:{prev:k(x,"coverage","less"),next:k(x,"coverage","greater")},color:{prev:k(x,"color","less"),next:k(x,"color","greater")},force:[]};f.includes(b.indexOf(y)+1)?w.force=[b[b.indexOf(y)+10]]:f.includes(b.indexOf(y))&&(w.force=[b[b.indexOf(y)-10]]),function(e,t,i,r){t.innerHTML="",document.title="Web - "+e.title,document.body.style.backgroundColor=c.stringify(e.mainColor);let o={complexity:{prev:0,next:0},coverage:{prev:0,next:0},force:0};e.elements.descendants.forEach(t=>{if(!t.visibility)return;let n=null;if(t.content!==u.NONE){if(o.force<r.force.length)n=r.force[o.force],o.force++,M.push(n);else switch(t.content){case u.RADIO_BUTTON:n=r.complexity.prev[o.complexity.prev%r.complexity.prev.length],o.complexity.prev++;break;case u.SELECT:n=r.complexity.next[o.complexity.next%r.complexity.next.length],o.complexity.next++;break;case u.INPUT:n=r.coverage.prev[o.coverage.prev%r.coverage.prev.length],o.coverage.prev++;break;case u.BUTTON:n=r.coverage.next[o.coverage.next%r.coverage.next.length],o.coverage.next++;break;case u.IMAGE:let a=t.colors.background,l=Object.keys(i).reduce((t,n)=>{let r=i[n],o=c.distanceSquared(a,r);return o<t.distance&&n!=e.id&&(t.distance=o,t.color=a,t.id=n),t},{distance:1/0,color:null,id:null});n=l.id}}n&&(t.link=n,M.push(n))}),function e(t,i,r){let o=document.createElement("div");if(o.classList.add("element"),o.style.flexBasis=`${100*i.basis}%`,o.style.flexGrow=1,o.style.flexDirection=r%2?"column":"row",o.style.padding=i.padding.map(e=>`${100*e}%`).join(" "),o.style.margin=`min(${10*Math.round(i.margin)}px, ${Math.round(i.margin)}%)`,o.style.width=`${100*i.coverage}%`,i.visibility&&(o.style.backgroundColor=c.stringify(i.colors.background),o.style.borderWidth="1px",o.style.borderStyle="solid",o.style.borderColor=`${c.stringify(i.colors.border.top)} ${c.stringify(i.colors.border.right)} ${c.stringify(i.colors.border.bottom)} ${c.stringify(i.colors.border.left)}`),0!==i.alignment&&(o.style.alignSelf=["start","center","end"][i.alignment-1]),0!==i.shadow&&i.visibility){let e=Math.floor(15*i.shadow+5);o.style.boxShadow=`${e}px ${e}px ${2*e}px #000C`,o.style.zIndex=i.zIndex}if(i.visibility){let e=null,t=null;switch(i.content){case u.NONE:break;case u.RADIO_BUTTON:e="change";let r=Array(Math.floor(3*i.contentSize)+2).fill(0).map(()=>\'<input type="radio" name="r">\');r[Math.floor(i.contentValue*r.length)]=\'<input type="radio" name="r" checked>\',t=`<form>${r.join("")}</form>`;break;case u.SELECT:e="change",t=`<select style="background-color: ${c.stringify(i.colors.content.high)}"">${Array.from({length:Math.floor(15*i.contentSize+2)}).fill("<option></option>").join("")}</select>`;break;case u.INPUT:e="click",t=`<input type="text" style="width: ${18*(Math.floor(6*i.contentSize)+3)}px; height: 18px; background-color: ${c.stringify(i.colors.content.high)}; border-top-color: ${c.stringify(i.colors.content.high)}; border-left-color: ${c.stringify(i.colors.content.high)}; border-right-color: ${c.stringify(i.colors.content.low)}; border-bottom-color: ${c.stringify(i.colors.content.low)};">`;break;case u.BUTTON:e="click",t=`<button style="width: ${18*(Math.floor(4*i.contentSize)+1)}px; height: 18px; background-color: ${c.stringify(i.colors.content.low)}; border-top-color: ${c.stringify(i.colors.content.high)}; border-left-color: ${c.stringify(i.colors.content.high)}; border-right-color: ${c.stringify(i.colors.content.low)}; border-bottom-color: ${c.stringify(i.colors.content.low)};"></button>`;break;case u.IMAGE:t=null===n.oid?`<a href=${i.link?`?id=${i.link}`:"#"} style="display: block; border: none;"><img src="#" style="width: 100%; height: 100%;"></a>`:\'<img src="#" style="width: 100%; height: 100%;">\'}null!==t&&(o.innerHTML=t,i.link&&null!==e&&null===n.oid&&o.children[0].addEventListener(e,e=>{window.location.href=`?id=${i.link}`}))}t.appendChild(o),i.children.forEach(t=>{e(o,t,r+1)})}(t,e.elements,0)}(x[y],v,Object.keys(x).reduce((e,t)=>(e[t]=x[t].mainColor,e),{}),w),Object.keys(x).forEach(e=>{let t=[];x[e].elements.visibility&&t.push(x[e].elements.colors.background),t.push(...x[e].elements.descendants.filter(e=>e.visibility).map(e=>e.colors.background)),x[e].colors=t,delete x[e].elements});const E=document.createElement("canvas"),I=E.getContext("2d");E.width=16,E.height=16,function(e,t,n,i){t.fillStyle=c.stringify(e.mainColor,1),t.fillRect(n,i,16,16);let r=e.colors;t.fillStyle=c.stringify(r[0],1),t.fillRect(n+2,i+2,12,12),r=r.map(e=>{let t=c.rgbToHsv(e);return{...e,...t}}).sort((e,t)=>t.s-e.s);for(let e=0;e<12;e++)for(let o=0;o<12;o++){let a=o+12*e,l=a/144,s=Math.floor(l*(r.length-1)),d=r[s];t.fillStyle=c.stringify(d,1),t.fillRect(n+2+e,i+2+o,1,1)}}(x[y],I,0,0);const O=document.createElement("link");O.type="image/x-icon",O.rel="shortcut icon",O.href=E.toDataURL("image/x-icon"),document.getElementsByTagName("head")[0].appendChild(O);</script></body></html>';

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (descriptor != address(0)) {
            return IDescriptor(descriptor).tokenURI(tokenId);
        }
        TokenData memory token = tokenData[tokenId];
        string memory description = "Web is a monument to the hyperlink, a poem dedicated to machine learning and a computer's d\u00E9rive within itself.\\n \\n The project is a fully on-chain generative cross-linked network of webpages released in partnership with Fingerprints DAO and is a coproduction with Superposition. Blockchain development by Jake Allen.";
        string memory finalTemplate = Base64.encode(bytes(string(abi.encodePacked(templateA, token.seed, templateB))));
        string memory json1 = string(abi.encodePacked('{"name":"', token.name, '", "description":"', description, '", "image": "ipfs://', ipfsHash, '/', tokenId.toString() ,'.png", '));
        string memory json2 = string(abi.encodePacked('"animation_url":"data:text/html;base64,', finalTemplate, '", "attributes":[{"trait_type":"Color","value":"', colorOptions[token.color],'"}, {"trait_type":"Complexity", "value":"', complexityOptions[token.complexity],'"}, {"trait_type": "Coverage", "value": "', coverageOptions[token.coverage],'"}], "external_url": "', externalUrl, token.seed, '"}'));
        string memory encodedJson = Base64.encode(bytes(string(abi.encodePacked(json1, json2))));
        return string(abi.encodePacked('data:application/json;base64,', encodedJson));
    }

    /// @dev check whether the merkleProof is valid for a given address and root
    function checkMerkleProof(
        bytes32[] calldata merkleProof,
        address _address,
        bytes32 _root
    ) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(merkleProof, _root, leaf);
    }

    //======================= ADMIN FUNCTIONS ================================

    function updateConfig(
        uint64 startTime,
        uint64 endTime,
        uint256 startPriceInWei, // 1 eth
        uint256 endPriceInWei, // .1 eth
        address payable fundsRecipient
    ) external onlyOwner {
        config.startTime = startTime;
        config.endTime = endTime;
        config.startPriceInWei = startPriceInWei;
        config.endPriceInWei = endPriceInWei;
        config.fundsRecipient = fundsRecipient;
    }

    function withdraw() external nonReentrant {
        uint256 funds = address(this).balance;

        // Payout recipient
        (bool sent, ) = config.fundsRecipient.call{
            value: funds,
            gas: FUNDS_SEND_GAS_LIMIT
        }("");
        require(sent, "Ether not withdrawn");
    }

    function adminMint(address to, uint256 tokenId) external onlyOwner {
        tokenIsMinted[tokenId] = true;
        supplyCount++;

        _safeMint(to, tokenId);
    }

    function addTokenData(TokenData[] memory _tokenData) external onlyOwner {
        for (uint i = 0; i < _tokenData.length; i++) {
            tokenData.push(_tokenData[i]);
        }
    }

    function updateMerkleRoots(bytes32 _holderRoot, bytes32 _fbMemberRoot, bytes32 _communityRoot) external onlyOwner {
        holderMerkleRoot = _holderRoot;
        fpMembersMerkleRoot = _fbMemberRoot;
        communitiesMerkleRoot = _communityRoot;
    }

    function updateIPFSHash(string memory _hash) external onlyOwner {
        ipfsHash = _hash;
    }

    function updateExternalURL(string memory _url) external onlyOwner {
        externalUrl = _url;
    }

    function updateDelegateAddress(address _address) external onlyOwner {
        delegationRegistry = IDelegationRegistry(_address);
    }

    function setDescriptor(address _descriptor) external onlyOwner {
        descriptor = _descriptor;
    }
}