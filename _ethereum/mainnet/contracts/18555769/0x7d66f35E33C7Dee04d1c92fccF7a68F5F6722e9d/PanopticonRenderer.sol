// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IScriptyBuilderV2.sol";
import "./LibString.sol";
import "./Base64.sol";
import "./PanopticonTraits.sol";
import "./IPanopticonRenderer.sol";
import "./IThumbnailer.sol";
import "./Freezable.sol";
import "./Strings.sol";

contract PanopticonRenderer is IPanopticonRenderer, PanopticonTraits, Freezable {
    address public scriptyStorageAddress;
    address public scriptyBuilderAddress;
    address public ethfsFileStorageAddress;
    IThumbnailer public thumbnailer;

    constructor(
        address _scriptyStorageAddress,
        address _scriptyBuilderAddress,
        address _ethfsFileStorageAddress,
        address _thumbnailerAddress
    ) {
        scriptyStorageAddress = _scriptyStorageAddress;
        scriptyBuilderAddress = _scriptyBuilderAddress;
        ethfsFileStorageAddress = _ethfsFileStorageAddress;
        thumbnailer = IThumbnailer(_thumbnailerAddress);
    }

    function getName(uint256 tokenId) public pure returns (string memory) {
        return string.concat("Panopticon #", LibString.toString(tokenId));
    }

    function getImage(uint256 tokenId, uint256 /* tokenHash */ ) external view returns (string memory) {
        if (address(thumbnailer) == address(0)) {
            return "";
        }

        return string(thumbnailer.getThumbnailUrl(tokenId));
    }

    function getHTML(uint256 tokenId, uint256 tokenHash) external view returns (string memory) {
        HTMLRequest memory htmlRequest = _getHtmlRequest(tokenId, tokenHash);
        return IScriptyBuilderV2(scriptyBuilderAddress).getHTMLString(htmlRequest);
    }

    function getMetadata(uint256 tokenId, uint256 tokenHash) external view returns (string memory) {
        return string(_getMetadata(tokenId, tokenHash));
    }

    function setConfig(
        address _scriptyStorageAddress,
        address _scriptyBuilderAddress,
        address _ethfsFileStorageAddress,
        address _thumbnailerAddress
    ) external onlyOwner notFrozen {
        scriptyStorageAddress = _scriptyStorageAddress;
        scriptyBuilderAddress = _scriptyBuilderAddress;
        ethfsFileStorageAddress = _ethfsFileStorageAddress;
        thumbnailer = IThumbnailer(_thumbnailerAddress);
    }

    function setDescription(string memory _description) external onlyOwner notFrozen {
        description = _description;
    }

    function setScript(string memory _script) external onlyOwner notFrozen {
        script = _script;
    }

    function setStyles(string memory _styles) external onlyOwner notFrozen {
        styles = _styles;
    }

    function setUi(string memory _ui) external onlyOwner notFrozen {
        ui = _ui;
    }

    function tokenURI(uint256 tokenId, uint256 tokenHash) external view override returns (string memory) {
        bytes memory metadata = _getMetadata(tokenId, tokenHash);
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function _getMetadata(uint256 tokenId, uint256 tokenHash) internal view returns (bytes memory) {
        HTMLRequest memory htmlRequest = _getHtmlRequest(tokenId, tokenHash);
        bytes memory base64EncodedHTMLDataURI = IScriptyBuilderV2(scriptyBuilderAddress).getEncodedHTML(htmlRequest);

        return abi.encodePacked(
            "{\"name\":\"",
            getName(tokenId),
            "\",",
            "\"description\":\"",
            description,
            "\",",
            "\"attributes\":[",
            _getJsonAttributes(tokenHash),
            "],",
            _getImage(tokenId),
            "\"animation_url\":\"",
            base64EncodedHTMLDataURI,
            "\"}"
        );
    }

    function _getImage(uint256 tokenId) internal view returns (bytes memory) {
        if (address(thumbnailer) == address(0)) {
            return "";
        }

        return abi.encodePacked("\"image\":\"", thumbnailer.getThumbnailUrl(tokenId), "\",");
    }

    function _getJsonAttributes(uint256 tokenHash) internal view returns (string memory) {
        string[] memory traitKeys = getTraitKeys();
        string memory result = "";

        for (uint256 i = 0; i < traitKeys.length; i++) {
            result = string.concat(
                result, _getTraitAsERC721JsonProperty(traitKeys[i], tokenHash), i + 1 < traitKeys.length ? "," : ""
            );
        }

        return result;
    }

    function _getHtmlRequest(uint256 tokenId, uint256 tokenHash) internal view returns (HTMLRequest memory) {
        HTMLRequest memory htmlRequest;
        htmlRequest.headTags = _getHeadTags(tokenId, tokenHash);
        htmlRequest.bodyTags = _getBodyTags();
        return htmlRequest;
    }

    function _getHeadTags(uint256 tokenId, uint256 tokenHash) internal view returns (HTMLTag[] memory) {
        HTMLTag[] memory headTags = new HTMLTag[](3);

        headTags[0].tagOpen =
            '<meta name="viewport" content="width=device-width,initial-scale=1.0">';
        headTags[0].tagContent = bytes(" ");
        headTags[0].tagClose = "";
        headTags[1].tagOpen = "<style>";
        headTags[1].tagContent = bytes(styles);
        headTags[1].tagClose = "</style>";
        headTags[2].tagType = HTMLTagType.script;
        headTags[2].tagContent = _getTokenDataScript(tokenId, tokenHash);

        return headTags;
    }

    function _getTokenDataScript(uint256 tokenId, uint256 tokenHash) internal view returns (bytes memory) {
        string memory traitsJs = "";
        for (uint256 i = 0; i < getTraitKeys().length; i++) {
            TokenTrait memory trait = getTrait(getTraitKeys()[i], tokenHash);

            traitsJs = string.concat(
                traitsJs,
                trait.traitKey,
                ":",
                LibString.toString(trait.valueIndex),
                i + 1 < getTraitKeys().length ? "," : ""
            );
        }

        return abi.encodePacked(
            "var inputData={tokenId:",
            LibString.toString(tokenId),
            ",hash:'",
            Strings.toHexString(tokenHash),
            "',",
            traitsJs,
            "};"
        );
    }

    function _getBodyTags() internal view returns (HTMLTag[] memory) {
        HTMLTag[] memory bodyTags = new HTMLTag[](4);

        bodyTags[0].name = "p5-v1.5.0.min.js.gz";
        bodyTags[0].tagType = HTMLTagType.scriptGZIPBase64DataURI;
        bodyTags[0].contractAddress = ethfsFileStorageAddress;

        bodyTags[1].name = "gunzipScripts-0.0.1.js";
        bodyTags[1].tagType = HTMLTagType.scriptBase64DataURI;
        bodyTags[1].contractAddress = ethfsFileStorageAddress;

        bodyTags[2].tagType = HTMLTagType.script;
        bodyTags[2].tagContent = bytes(script);

        bodyTags[3].tagType = HTMLTagType.script;
        bodyTags[3].tagContent = bytes(ui);

        return bodyTags;
    }

    string public description =
        "Are you looking at it, or is it looking at you?";
    string public styles =
        "*{box-sizing:border-box}body,html{height:100%;width:100%;margin:0;padding:0}body{background-color:black;display:flex;justify-content:center;align-items:top;overflow:hidden}";
    string public ui = 
        "let wrs,fs;function windowResized(){clearTimeout(wrs);wrs=setTimeout(()=>{setup()},400)}function exportAsImage(){saveCanvas('panopticon-'+inputData.tokenId,'png')}function toggleMode(){responsive=!responsive;setup()}function toggleFs(){fs=!fs;fullscreen(fs)}function keyPressed(){if(key==='r'){toggleMode()}if(key==='s'){exportAsImage()}if(key==='f'){toggleFs()}}document.addEventListener('dblclick',toggleMode);";
    string public script =
        "let atIndex,maxIndex,completed,eyes,responsive,sl,R,CP_R,H,W,Z,TX,TY,SH,SW,GH,GW,NX,NY,SU,DV,DH,CA_1,CA_2,CX_1,CX_2,CX_3,CX_4,CY_1,CY_2,CY_3,CY_4,P_DEF,OFF,C_SEL,IL_X,IL_Y,DEPTH_1,DEPTH_2,BG_G,IC_F1,IC_F2,IC_F3,EC_F,EC_1,BG_COL,BG_COL_2,BG_COL_3,RG,GD,NS,NE,PO,IR_R,PU_R,SP,L_COL;let{R_PAL,ET,PT,SF,NT,LINED,DT,IC_M,EC_M,BORDER,tokenId}=inputData;let C_SW1=.025,C_SW2=1.5,C_SW3=.075,FR=60;function setZoom(z){let s=document.body.style;if(navigator.userAgent.indexOf('Firefox')!==-1){s.alignItems='center';s.transform='scale('+z+')'}else{s.zoom=z}}function getResponsiveConfig(ww,wh){return[ww,wh,1]}function getPortraitConfig(ww,wh){let w=900,h=1200,z=Math.min(wh/h,ww/w).toFixed(4);return[w,h,z]}function getPixelDensity(z){return z>.5&&navigator.userAgent.indexOf('Safari')!==-1&&navigator.userAgent.indexOf('Chrome')===-1?4:2}function getBatchSize(total){return total/200}function setup(){eyes=[];CP_R=[];R=new Random;if(responsive){[W,H,Z]=getResponsiveConfig(windowWidth,windowHeight)}else{[W,H,Z]=getPortraitConfig(windowWidth,windowHeight)}setZoom(Z);createCanvas(W,H);rectMode(CORNER);colorMode(HSL,360);frameRate(FR);pixelDensity(getPixelDensity(Z));SH=R.random_int(SF_RANGES[SF][0],SF_RANGES[SF][1]);SW=SH;if(R.random_bool(.1)){SH=SW*2}RG=R.random_bool(.5);GH=17.5*SH;GW=17.5*SW;GD=Math.floor(R_VAL(GD_OPTS));NX=W/GW*2;NY=H/GH*4-1;PO=R_VAL(PO_OPTS);SU=R.random_bool(.3);TX=R.random_num(-2e3,2e3);TY=R.random_num(-2e3,2e3);BG_X=R.random_num(0,W);BG_Y=R.random_num(0,H);NS=Math.floor(R_VAL(NS_OPTS));NE=parseInt(inputData.hash.slice(2,10),16);noiseSeed(NE);if(DT===0){DV=.01;DH=.01}else if(DT===1){DV=R_VAL(DA_OPTS);DH=.1}else if(DT===2){DV=R_VAL(DA_OPTS);DH=R_VAL(DA_OPTS)}if(LINED){noFill();sl=C_SW2}else{sl=C_SW3}P_DEF=R.random_num(2,8);strokeWeight(sl);C_SEL=inputData.C_SEL;let DIR=R.random_num(0,1)>.5;if(DIR){IL_X=R_VAL(lerpX);IL_Y=R_VAL(lerpY)}else{IL_X=R.random_num(-2,2);IL_Y=R.random_num(-2,2)}if(SU){depth=Math.floor(R_VAL(SUBS_OPTS))}else{depth=0}SP=pals[R_PAL].map(val=>`hsl(${val})`);BG_COL_2=R_Col(SP);BG_COL_3=R_Col(SP);L_COL=SP[SP.length-1];setCol(IC_M,EC_M,C_SEL);background(BG_COL);BG()}function BG(){BG_G=RG?drawingContext.createLinearGradient(BG_X,BG_Y,W,H):drawingContext.createRadialGradient(TX,TY,0,BG_X,BG_Y,W);BG_G.addColorStop(0,BG_COL);BG_G.addColorStop(.5,BG_COL_2);BG_G.addColorStop(1,BG_COL_3);drawingContext.fillStyle=BG_G;rect(0,0,W,H);BRD()}function BRD(){push();rectMode(CORNER);noFill();stroke(BG_COL);strokeWeight(responsive?Math.min(windowWidth,windowHeight)*.07:70);rect(0,0,W,H);pop()}function setCol(IC_M,EC_M,colMode){if(colMode===0){BG_COL=R_Col(SP);SP=SP.filter(c=>c!==BG_COL)}else if(colMode===1){BG_COL=SP[0];i_fx=SP[SP.length-1];SP=SP.slice(1,-1)}if(IC_M===1){IC_F1=R_Col(SP);IC_F2=R_Col(SP);IC_F3=R_Col(SP)}if(EC_M===1){EC_F=R_Col(SP)}let IC_1,IC_2,IC_3;for(let j=0;j<NY;j++){let n=j%2?NX:NX-1;let start=j%2?0:GW/2;for(let i=0;i<n;i++){let x=start+GW/2+i*GW+R.random_num(-GW*PO,GW*PO);let y=GH/2+GH/2*j+R.random_num(-GH*PO,GH*PO);let w=GW;let h=GH;OFF=R.random_num(-2,2);DEPTH_1=R.random_bool(.5);DEPTH_2=R.random_bool(.9);switch(IC_M){case 0:IC_1=R_Col(SP);IC_2=R_Col(SP);IC_3=R_Col(SP);break;case 1:IC_1=IC_2=IC_3=IC_F1;break;case 2:IC_1=IC_2=IC_3=R_Col(SP);break}switch(EC_M){case 0:EC_1=R_Col(SP);break;case 1:EC_1=EC_F;break;case 2:EC_1=IC_1;break}eyes.push({x:x,y:y,w:w,h:h,IC_1:IC_1,IC_2:IC_2,IC_3:IC_3,EC_1:EC_1,OFF:OFF,DEPTH_1:DEPTH_1,DEPTH_2:DEPTH_2})}}atIndex=0;maxIndex=eyes.length;completed=false}function draw(){if(completed){return}let batchMaxIndex=Math.min(atIndex+Math.max(1,getBatchSize(maxIndex)),eyes.length);push();translate(-W/2,-H/2);while(atIndex<batchMaxIndex){eye(eyes[atIndex++])}pop();if(BORDER){BRD()}completed=atIndex>=maxIndex;if(completed){push();blendMode(SCREEN);granulate(15);pop()}if(typeof renderInfoCallback==='function'){renderInfoCallback({atIndex:atIndex,maxIndex:maxIndex,completed:completed})}}function eye(eyeObj,n=1){let{x,y,w,h,IC_1,IC_2,IC_3,EC_1,SW,OFF,DEPTH_1,DEPTH_2}=eyeObj;IR_R=R_VAL(IS_S_OPTS);PU_R=R_VAL(PS_S_OPTS);if(DEPTH_1<DEPTH_2&&n<=depth){n++;eye({x:x+OFF,y:y-h/4+OFF,w:w/2+OFF,h:h/2+OFF,IC_1:IC_1,IC_2:IC_2,IC_3:IC_3,EC_1:EC_1},n);eye({x:x+OFF,y:y+h/4+OFF,w:w/2+OFF,h:h/2+OFF,IC_1:IC_1,IC_2:IC_2,IC_3:IC_3,EC_1:EC_1},n);eye({x:x-w/4+OFF,y:y+OFF,w:w/2+OFF,h:h/2+OFF,IC_1:IC_1,IC_2:IC_2,IC_3:IC_3,EC_1:EC_1},n);eye({x:x+w/4+OFF,y:y+OFF,w:w/2+OFF,h:h/2+OFF,IC_1:IC_1,IC_2:IC_2,IC_3:IC_3,EC_1:EC_1},n)}else{let pts=[{x:x-w/2,y:y},{x:x,y:y-h/2},{x:x+w/2,y:y},{x:x,y:y+h/2}].map(({x,y})=>{for(let i=0;i<GD;i++){let angle=(customNoise(x,y,NT)-.02)*TAU;let v=p5.Vector.fromAngle(angle);v.setMag(10);x+=v.x;y+=v.y}return{x:x,y:y}});for(let i=0;i<GD*10;i++){CP_R.push({pt1:R.random_int(0,3),pt2:R.random_int(0,3),pt3:R.random_int(0,3),pt4:R.random_int(0,3)})}if(!LINED){push();strokeWeight(C_SW1);noFill();for(let i=0;i<GD*P_DEF;i++){curve(pts[CP_R[i].pt1].x+OFF,pts[CP_R[i].pt1].y+OFF,pts[1].x+OFF,pts[CP_R[i].pt2].y+OFF,pts[CP_R[i].pt3].x+OFF,pts[CP_R[i].pt3].y+OFF,pts[CP_R[i].pt4].x+OFF,pts[CP_R[i].pt4].y+OFF);curve(pts[CP_R[i].pt1].x+OFF,pts[CP_R[i].pt1].y+OFF,pts[0].x+OFF,pts[CP_R[i].pt2].y+OFF,pts[CP_R[i].pt3].x+OFF,pts[CP_R[i].pt3].y+OFF,pts[CP_R[i].pt4].x+OFF,pts[CP_R[i].pt4].y+OFF)}pop()}let MN_X=Math.min(...pts.map(pt=>pt.x));let MX_X=Math.max(...pts.map(pt=>pt.x));let MN_Y=Math.min(...pts.map(pt=>pt.y));let MX_Y=Math.max(...pts.map(pt=>pt.y));let boxW=MX_X-MN_X;let boxH=MX_Y-MN_Y;let IS=Math.min(boxW,boxH)*IR_R;let PS=IS*PU_R;push();drawingContext.save();drawingContext.shadowOffsetX=0;drawingContext.shadowOffsetY=0;drawingContext.shadowBlur=GW;drawingContext.shadowColor=color(0,0,0,100);if(LINED){stroke(EC_1)}else{fill(EC_1)}switch(ET){case 0:beginShape();vertex(pts[0].x,pts[0].y);bezierVertex(lerp(pts[0].x,pts[1].x,DH),lerp(pts[0].y,pts[1].y,DV),lerp(pts[1].x,pts[2].x,DH),lerp(pts[1].y,pts[2].y,DV),pts[2].x,pts[2].y);bezierVertex(lerp(pts[2].x,pts[3].x,DH),lerp(pts[2].y,pts[3].y,DV),lerp(pts[3].x,pts[0].x,DH),lerp(pts[3].y,pts[0].y,DV),pts[0].x,pts[0].y);endShape(CLOSE);break;case 1:beginShape(QUADS);vertex(pts[0].x,pts[0].y);vertex(pts[1].x,pts[1].y);vertex(pts[2].x,pts[2].y);vertex(pts[3].x,pts[3].y);endShape(CLOSE);break;case 2:let TL=pts[0];let TR={x:pts[2].x,y:pts[0].y};let BR=pts[2];let BL={x:pts[0].x,y:pts[2].y};let MH=10;if(Math.abs(TR.x-TL.x)<MH){TR.x=TL.x+(TR.x>TL.x?MH:-MH);BR.x=TR.x}if(Math.abs(BL.y-TL.y)<MH){BL.y=TL.y+(BL.y>TL.y?MH:-MH);BR.y=BL.y}beginShape(QUADS);vertex(TL.x,TL.y);vertex(TR.x,TR.y);vertex(BR.x,BR.y);vertex(BL.x,BL.y);endShape(CLOSE);break}drawingContext.clip();let centerX=(pts[0].x+pts[1].x+pts[2].x+pts[3].x)/4;let centerY=(pts[0].y+pts[1].y+pts[2].y+pts[3].y)/4;let dirX=TX-centerX;let dirY=TY-centerY;let length=Math.sqrt(dirX*dirX+dirY*dirY);dirX/=length;dirY/=length;let irisOffsetX=boxW*.2;let irisOffsetY=boxH*.15;dirX*=irisOffsetX;dirY*=irisOffsetY;IX=centerX+dirX;IY=centerY+dirY;let gradient=drawingContext.createRadialGradient(IX,IY,0,IX,IY,IS);push();drawingContext.shadowOffsetX=0;drawingContext.shadowOffsetY=0;drawingContext.shadowBlur=GW/2;drawingContext.shadowColor=color(0,0,0,150);if(LINED){noFill();stroke(IC_1)}else{gradient.addColorStop(0,IC_1);gradient.addColorStop(.5,IC_2);gradient.addColorStop(1,IC_3);drawingContext.fillStyle=gradient}ellipse(IX,IY,IS);pop();push();drawingContext.shadowOffsetX=0;drawingContext.shadowOffsetY=0;drawingContext.shadowBlur=40*SW/2;drawingContext.shadowColor=color(0,0,0,150);if(LINED){stroke(IC_1)}else{gradient.addColorStop(0,IC_1);gradient.addColorStop(1,IC_2);drawingContext.fillStyle=gradient}drawingContext.shadowOffsetX=0;drawingContext.shadowOffsetY=0;drawingContext.shadowBlur=20*SW;drawingContext.shadowColor=color(360,360,360,75);if(!LINED){fill(L_COL)}if(PT===0){ellipse(IX,IY,PS,PS)}else if(PT===1){ellipse(IX,IY,PS/5,PS)}else if(PT===2){push();rectMode(CENTER);rect(IX,IY,PS,PS,PS/20);pop()}pop();drawingContext.restore();pop()}}function customNoise(x,y,type){switch(type){case 0:default:return noise(x/NS,y/NS);case 1:angle=Math.atan(y-TY,x-TX);return noise(x/NS,y/NS)*Math.sin(angle*dist(x,y,TX,TY)*.01);case 2:return Math.sin(x*.05)*Math.cos(y*.05)+noise(x/NS,y/NS);case 3:let d=dist(x,y,TX,TY);return Math.sin(d*.05)+noise(x/NS,y/NS)}}function granulate(amount){loadPixels();let d=pixelDensity();let pixelsCount=4*(width*d)*(height*d);for(let i=0;i<pixelsCount;i+=4){let grainAmount=R.random_num(-amount,amount);pixels[i]=pixels[i]+grainAmount;pixels[i+1]=pixels[i+1]+grainAmount;pixels[i+2]=pixels[i+2]+grainAmount}updatePixels()}class Random{constructor(){this.useA=false;let sfc32=function(uint128Hex){let a=parseInt(uint128Hex.substring(0,8),16);let b=parseInt(uint128Hex.substring(8,16),16);let c=parseInt(uint128Hex.substring(16,24),16);let d=parseInt(uint128Hex.substring(24,32),16);return function(){a|=0;b|=0;c|=0;d|=0;let t=(a+b|0)+d|0;d=d+1|0;a=b^b>>>9;b=c+(c<<3)|0;c=c<<21|c>>>11;c=c+t|0;return(t>>>0)/4294967296}};this.prngA=new sfc32(inputData.hash.substring(2,34));this.prngB=new sfc32(inputData.hash.substring(34,66));for(let i=0;i<1e6;i+=2){this.prngA();this.prngB()}}random_dec(){this.useA=!this.useA;return this.useA?this.prngA():this.prngB()}random_num(a,b){return a+(b-a)*this.random_dec()}random_int(a,b){return Math.floor(this.random_num(a,b+1))}random_bool(p){return this.random_dec()<p}random_choice(list){return list[this.random_int(0,list.length-1)]}}let SF_RANGES=[[2,3],[3,7],[7,10],[10,20],[20,30]];let GD_OPTS=[{value:[1,10],rarity:.3},{value:[10,20],rarity:.4},{value:[30,40],rarity:.2},{value:[40,50],rarity:.1},{value:[50,60],rarity:.1}];let NS_OPTS=[{value:[100,600],rarity:.2},{value:[600,1600],rarity:.5},{value:[1600,2200],rarity:.3}];let SUBS_OPTS=[{value:[0,1],rarity:.2},{value:[1,2],rarity:.5}];let ET_OPTS=[{value:[0,1],rarity:.5},{value:[1,2],rarity:.5}];let PO_OPTS=[{value:[0,.05],rarity:.5},{value:[.1,.2],rarity:.4},{value:[.2,.5],rarity:.1}];let DA_OPTS=[{value:[0,0],rarity:.7},{value:[-1,1],rarity:.05},{value:[-4,4],rarity:.3}];let IS_S_OPTS=[{value:[.5,.75],rarity:.7},{value:[.75,1],rarity:.2}];let PS_S_OPTS=[{value:[.2,.3],rarity:.7},{value:[.3,.6],rarity:.2}];let lerpX=[{value:[0,.5],rarity:.6},{value:[.5,1],rarity:.4}];let lerpY=[{value:[0,.5],rarity:.6},{value:[.5,1],rarity:.4}];function R_VAL(arr){let r=R.random_dec();let sum=0;for(let item of arr){sum+=item.rarity;if(r<=sum)return R.random_num(item.value[0],item.value[1])}let lastItem=arr[arr.length-1];return R.random_num(lastItem.value[0],lastItem.value[1])}let pals=[['45,0%,80%','0,0%,90%','210,71%,62%','224,37%,55%','288,23%,59%','288,33%,75%','0,67%,80%','2,73%,62%','45,71%,66%','115,48%,51%','0,0%,24%'],['46,100%,50%','0,0%,90%','28,90%,75%','28,90%,50%','14,94%,47%','0,100%,50%','350,71%,43%','231,52%,63%','0,0%,24%'],['196,57%,82%','0,0%,90%','217,64%,41%','196,62%,51%','170,90%,66%','176,68%,41%','166,59%,42%','0,0%,24%'],['82,45%,81%','0,0%,90%','45,71%,66%','65,82%,62%','95,64%,54%','100,44%,38%','90,50%,20%','0,0%,24%'],['165,49%,72%','0,0%,90%','45,71%,66%','65,82%,62%','138,56%,52%','168,70%,63%','224,37%,55%','288,23%,59%','288,33%,75%','0,67%,80%','0,0%,24%'],['150,20%,20%','0,0%,90%','298,30%,40%','333,40%,49%','34,50%,50%','49,60%,55%','117,30%,44%','174,45%,45%','220,50%,40%','15,0%,100%'],['330,29%,80%','0,0%,90%','311,65%,89%','351,37%,60%','345,78%,54%','302,81%,40%','50,100%,62%','0,10%,22%'],['40,80%,80%','0,0%,90%','30,60%,45%','30,50%,40%','65,40%,60%','70,40%,50%','110,25%,35%','20,75%,15%'],['6,68%,82%','0,0%,90%','6,64%,66%','6,68%,47%','0,100%,50%','38,100%,62%','50,100%,62%','0,10%,22%'],['0,0%,14%','0,0%,7%','220,7%,25%','210,9%,33%','210,6%,45%','210,8%,65%','0,0%,90%'],['194,88%,30%','148,88%,18%','241,71%,27%','292,70%,7%','0,71%,31%','317,54%,32%','43,81%,37%','241,98%,4%']];function R_Col(colorsArray){return R.random_choice(colorsArray)}";
}