// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./ERC721.sol";
import "./Utils.sol";
import "./SVG.sol";
import "./IPainter16.sol";
import "./IPainter256.sol";

/// @title Together 5ever
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract Together5ever is ERC721 {
    address internal _onchainDinosAddress;
    address internal _togetherAddress;

    constructor(address onchainDinosAddress, address togetherAddress) {
        _onchainDinosAddress = onchainDinosAddress;
        _togetherAddress = togetherAddress;

        _mint(msg.sender, 1);
    }

    function name() public pure override returns (string memory) {
        return "Together 5ever";
    }

    function symbol() public pure override returns (string memory) {
        return "5EVR";
    }

    /// @notice Get art for token.
    /// @param tokenId token id
    /// @return art
    function art(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) {
            revert();
        }

        string memory dino1 = string.concat(
            '<g id="d1" transform="translate(-80,20) scale(1,1)">', IPainter256(_onchainDinosAddress).art(29), "</g>"
        );
        string memory dino2 = string.concat(
            '<g id="d2" transform="translate(105,20) scale(-1,1)">', IPainter256(_onchainDinosAddress).art(19), "</g>"
        );

        string memory together1 =
            string.concat('<g transform="scale(1.5,1.5)">', IPainter16(_togetherAddress).art(64), "</g>");
        string memory together2 = string.concat(
            '<g id="t2" transform="translate(0,60) scale(.27,.27)">', IPainter16(_togetherAddress).art(882), "</g>"
        );

        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 400 400" style="display:block;margin:auto"><style>svg * {transform-origin: center;transform-box: fill-box;}</style><rect id="r1" width="100%" height="100%" y="0" fill="#abcdef" />',
            together1,
            '<rect id="r2" width="100%" height="50%" y="50%" fill="#303f82" />',
            dino1,
            dino2,
            together2,
            "</svg>"
        );
    }

    /// @notice Get token uri for token.
    /// @param tokenId token id
    /// @return tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory artSvg = art(tokenId);

        return Utils.formatTokenURI(
            Utils.svgToURI(artSvg),
            string.concat(
                "data:text/html;base64,",
                Utils.encodeBase64(
                    bytes(
                        string.concat(
                            '<html style="overflow:hidden"><body style="margin:0">',
                            artSvg,
                            '<script>let s=t=>new Promise(e=>setTimeout(e,t)),ready=!1;const kv=document.getElementsByTagName("svg").item(0).querySelectorAll("*");for(let j=0;j<kv.length;j++)kv[j].style&&(kv[j].style.strokeOpacity=0,kv[j].style.fillOpacity=0);(async()=>{for(let t=0;t<kv.length;t++){kv[t].style&&(kv[t].style.strokeOpacity=1,kv[t].style.fillOpacity=1),console.log(kv[t].tagName);let e=30;"line"===kv[t].tagName&&(e=5),await s(e)}await s(250),flipDinoHat("d2"),await s(250),flipDinoHat("d1"),ready=!0})();const flipDinoHat=t=>{let e,l;"6"===document.querySelector(`#${t} #a`).getAttribute("x")?(e="9",l="5"):(e="6",l="10"),document.querySelector(`#${t} #a`).setAttribute("x",e),document.querySelector(`#${t} #b`).setAttribute("x",l)};document.querySelector("#d1").addEventListener("click",()=>{ready&&flipDinoHat("d1")}),document.querySelector("#d2").addEventListener("click",()=>{ready&&flipDinoHat("d2")});let glitchDinos=!1,glitchBackgroundRects=!1,allRects=document.getElementsByTagName("rect"),a=!1,b=!1,o=Array.from(document.getElementsByTagName("line")).map(t=>t.style.stroke),r=Array.from(allRects).map(t=>t.style.fill),c=()=>Math.floor(256*Math.random()),d1=document.getElementById("d1"),d2=document.getElementById("d2");const dino1Rects=d1.querySelectorAll("rect"),dino2Rects=d2.querySelectorAll("rect");let leftArmState=0,innerArmsIdxes=[25,30,35],ogFillColors1=innerArmsIdxes.map(t=>dino1Rects.item(t).getAttribute("fill")),ogFillColors2=innerArmsIdxes.map(t=>dino2Rects.item(t).getAttribute("fill")),ogTransform1=d1.getAttribute("transform"),ogTransform2=d2.getAttribute("transform"),d1item32=dino1Rects.item(32),d2item32=dino2Rects.item(32),ogOuterPosition={y:+d1item32.getAttribute("y"),height:+d1item32.getAttribute("height")},t2=document.getElementById("t2"),ogTogether2Transform=t2.getAttribute("transform"),dancing=!1;const setFill=(t,e,l)=>{t.item(e).setAttribute("fill",l)},danceParty=async()=>{if(!dancing){for(t2.setAttribute("transform","translate(0,-150) scale(0.3,0.3)");b;)[{id:"d1",dinoRects:dino1Rects,ogFillColors:ogFillColors1},{id:"d2",dinoRects:dino2Rects,ogFillColors:ogFillColors2},].forEach(({id:t,dinoRects:e,ogFillColors:l})=>{let i=[];if(0===leftArmState?i=[1,0,2]:1===leftArmState||3===leftArmState?i=[0,1,2]:2===leftArmState&&(i=[0,2,1]),setFill(e,25,l[i[0]]),setFill(e,30,l[i[1]]),setFill(e,35,l[i[2]]),.2>Math.random()){let n=document.getElementById(t).getAttribute("transform"),[g,d]=n.split(" ");d=d.indexOf("-")>0?"scale(1,1)":"scale(-1,1)",document.getElementById(t).setAttribute("transform",g+" "+d)}let m;2===leftArmState?m=ogOuterPosition.y-ogOuterPosition.height:1===leftArmState||3===leftArmState?m=ogOuterPosition.y:0===leftArmState&&(m=ogOuterPosition.y+ogOuterPosition.height),e.item(32).setAttribute("y",m)}),4==++leftArmState&&(leftArmState=0),await s(200);d1item32.setAttribute("y",ogOuterPosition.y),d2item32.setAttribute("y",ogOuterPosition.y),innerArmsIdxes.forEach((t,e)=>{setFill(dino1Rects,t,ogFillColors1[e]),setFill(dino2Rects,t,ogFillColors2[e])}),d1.setAttribute("transform",ogTransform1),d2.setAttribute("transform",ogTransform2),t2.setAttribute("transform",ogTogether2Transform)}};document.body.addEventListener("click",async()=>{if(!ready||(a&&b&&glitchDinos&&(glitchBackgroundRects=!0),a&&b&&(glitchDinos=!0),!a||b))return;b=!0,danceParty();let t=document.getElementsByTagName("line"),e=document.querySelectorAll("#d1 rect, #d2 rect"),l=document.querySelectorAll("#r1, #r2");for(;a;){for(let i=0;i<t.length;i++)t[i].style.stroke=`rgb(${c()},${c()},${c()})`;if(glitchDinos)for(let n=0;n<e.length;n++)e[n].style.fill=`rgb(${c()},${c()},${c()})`;if(glitchBackgroundRects)for(let g=0;g<l.length;g++)l[g].style.fill=`rgb(${c()},${c()},${c()})`;await s(50)}for(let d=0;d<t.length;d++)t[d].style.stroke=o[d];for(let m=0;m<allRects.length;m++)allRects[m].style.fill=r[m];b=!1,glitchDinos=!1,glitchBackgroundRects=!1},!0),document.getElementById("r2").addEventListener("click",async()=>{if(!ready||a)return;a=!0;let t=document.getElementsByTagName("line");for(let e=0;e<2*t.length;e++){let l=e<t.length?"0":"1";t[e<t.length?e:2*t.length-e-1].style.strokeOpacity=l;let i=t.length%100;await s((e<t.length?e>=t.length-i:e>t.length&&e-t.length<=i)?20+(100-i)/100*75:10)}a=!1},!0);</script></body></html>'
                        )
                    )
                )
            ),
            string.concat(
                "[",
                Utils.getTrait("Firm", "Round", true),
                Utils.getTrait("Dino Wub", "29", true),
                Utils.getTrait("Dino Shmu", "19", true),
                Utils.getTrait("Together Wub", "64", true),
                Utils.getTrait("Together Shmu", "882", true),
                Utils.getTrait("Wub", "Ball", false),
                "]"
            )
        );
    }
}
