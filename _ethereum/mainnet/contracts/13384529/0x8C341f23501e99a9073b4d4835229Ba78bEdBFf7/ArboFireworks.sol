// SPDX-License-Identifier: MIT

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract ArboFireworks is ERC721Enumerable, Ownable {
    IERC721 public _arfes;

    //price variables
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;

    //supply variables
    uint256 public _maxSupply = 333;

    //sale state control variables
    bool public _isBurningEnabled = false;
    bool public _isMintingEnabled = false;
    bool public _isClaimingEnabled = false;

    //wallet to withdraw to
    address payable public _abar =
        payable(address(0x96f10441b25f56AfE30FDB03c6853f0fEC70F389));

    //metadata variables
    string private _baseURI_ = "http://localhost:3001/api/tokens/";
    uint256 private _tokenId;

    //artwork script
    string public _script = "let pg,seed=parseInt(tokenData.hash.slice(0,16),16);const firework=[],colors=['#c33f3f','#ffe63f','#609f65','#ff893f','#ad4dd0','#00c0f8','#636363','#FFFFFF','#2e40a9','#222222'],ccA=['#F085F2','#C55CF2','#7732D9','#F27E63','#F25252'],ccB=['#C33A32','#006E46','#F6B221','#880D53','#1E428A'];let gravity,rdn,count,frame,posX=[],num=[],type=[],dis=[],hh=[];const ss=150;let bg,pg2,pg3,colorId,frameStyle,branch,branchIdx,doBranch,step=0,fireColor=0;const json={},snap=isToSnap;function preload(){compose()}function setup(){createCanvas(600,600,WEBGL),noSmooth(),pg=createGraphics(ss,ss,WEBGL),pg2=createGraphics(600,600),pg3=createGraphics(600,600),canvas.imageSmoothingEnabled=!1,this._renderer.getTexture(pg).setInterpolation(NEAREST,NEAREST),pg.angleMode(DEGREES),pg.noSmooth(),pg.clear(),pg.background(0),pg2.clear(),pg2.image(bg,0,0),pg3.clear(),pg3.image(tree,0,0),gravity=createVector(0,.004)}function echo(){const e=color(colors[colorId]),o=red(e),t=red(e),r=red(e);pg.fill(o,t,r,10),pg.noStroke(),pg.rectMode(CENTER),pg.rect(0,0,ss,ss)}function noEcho(){background(0),pg.clear()}function doFire(e){if(null!=num[e])for(let o=0;o<num[e];o++)firework.push(new Ball(o,pos(posX[e]),type[e],num[e],dis[e],hh[e]))}function draw(){if(150==++step)pg2.clear(),pg2.image(bg,0,0),pg3.clear(),pg3.image(tree,0,0),doBranch<5&&pg3.image(branch,0,0);else if(step>160){if(echo(),5==(count=frameCount%500)?(doFire(0),doFire(10)):20==count?(doFire(1),doFire(11)):40==count?(doFire(2),doFire(12)):60==count?(doFire(3),doFire(13)):80==count?(doFire(4),doFire(14)):100==count?(doFire(5),doFire(15)):120==count?(doFire(6),doFire(16)):140==count?(doFire(7),doFire(17)):160==count?(doFire(8),doFire(18)):180==count&&(doFire(9),doFire(19)),firework.length>0)for(let e=0;e<firework.length;e++)firework[e].show(),firework[e].move(),firework[e].applyForce(gravity),firework[e].vel.y>0&&firework[e].boom(),firework[e].isDead()&&firework.splice(e,1);imageMode(CENTER),image(pg2,0,0,500,500),image(pg,0,0,500,500),blendMode(BLEND),image(pg3,0,0,500,500),noFill(),image(frame,0,0)}800==step&&snap&&(save(`${tokenData.tokenId}.png`),saveJSON(json,`${tokenData.tokenId}.json`),window.emitMetadataDownloaded&&setTimeout(()=>{window.emitMetadataDownloaded()},1e4))}class Ball{constructor(e,o,t,r,i,n){this.pos=createVector(o,88),this.vel=createVector(0,-.01),this.acel=createVector(0,-1),this.s=1,this.t=t,this.aux=!0,this.a=255,this.life=random(3,10),this.id=e,this.num=r,this.c=null,this.dis=i,this.hh=n}show(){pg.noStroke(),fireColor>1?(this.c=colors[colorId],pg.fill(this.c)):(this.cc=ccB[this.id%ccB.length],this.c=color(this.cc),pg.fill(this.c)),pg.ellipse(this.pos.x,this.pos.y,this.s,this.s),this.aux||(this.a-=random(2,this.life))}move(){this.vel.add(this.acel),this.vel.limit(this.hh),this.pos.add(this.vel),this.acel.mult(0)}applyForce(e){this.acel.add(e)}boom(){0==this.t?this.aux&&(this.x=cos(this.id/this.num*6.28),this.y=sin(this.id/this.num*6.28),this.acel=createVector(this.x,this.y),this.acel.normalize(),this.acel.mult(this.dis),this.aux=!1):1==this.t?this.aux&&(this.acel=p5.Vector.random2D(),this.acel.normalize(),this.acel.mult(random(this.dis)),this.aux=!1):2==this.t&&(this.acel=p5.Vector.random2D(),this.acel.normalize(),this.acel.mult(this.dis),this.aux=!1)}isDead(){return this.a<10}}function compose(){step=0,(rdn=new Random(seed)).random_dec(),colorId=rdn.random_int(0,10);const e=rdn.random_int(0,10);let o;o=!((fireColor=rdn.random_int(0,10))>1),branchIdx=0;let t,r,i,n,s=!1,a=!1;n=colors[colorId];const d=rdn.random_num(0,1);if(frameStyle=d>.95?5:d>.9?4:d>.8?3:d>.66?2:d>.33?1:0,frame=loadImage(`${imgBaseUrl}/frame_${frameStyle}.png`),e<7){s=!1;const e=rdn.random_int(0,9);t=e;const o=rdn.random_int(0,9);r=o,i=branchIdx=rdn.random_int(0,9),bg=loadImage(`${imgBaseUrl}/moon_${e}.png`),tree=loadImage(`${imgBaseUrl}/tree_${o}.png`)}else s=!0,bg=loadImage(`${imgBaseUrl}/moon_${colorId}.png`),tree=loadImage(`${imgBaseUrl}/tree_${colorId}.png`),branchIdx=colorId,t=colorId,r=colorId,i=colorId;(doBranch=rdn.random_int(0,10))<5?(branch=loadImage(`${imgBaseUrl}/t_${branchIdx}.png`),a=!0):i=null;const c=rdn.random_int(6,20);for(let e=0;e<c;e++)posX[e]=rdn.random_int(1,6),num[e]=rdn.random_int(5,30),type[e]=rdn.random_int(0,2),dis[e]=rdn.random_num(.4,.6),hh[e]=rdn.random_num(2,3);if(debug){const e=[`FrameStyle:${frameStyle}`,`SameColor:${s}`,`Branch:${a}`,`BgImg:${t}`,`TreeImg:${r}`,`BranchImg:${i}`,`FireworkColor:${n}`,`Shot:${c}`,`SpecialFirework:${o}`];console.log(e)}json['Frame Style']=frameStyle,json['Same Color']=s,json.Branch=a,json['Background Image']=t,json['Tree Image']=r,json['Branch Image']=i,json['Firework Color']=n,json.Shot=c,json['Special Firework']=o}function anchor(){push(),noFill(),stroke(255);for(let e=0;e<7;e++){const o=average(600,7,e)-300;ellipse(o,250,20,20)}pop()}function mousePressed(){debug&&(seed=int(random(1e4)),posX=[],colorg=[],num=[],type=[],dis=[],hh=[],compose())}function touchStarted(){debug&&(seed=int(random(1e4)),posX=[],colorg=[],num=[],type=[],dis=[],hh=[],compose())}class Random{constructor(e){this.seed=e}random_dec(){return this.seed^=this.seed<<13,this.seed^=this.seed>>17,this.seed^=this.seed<<5,(this.seed<0?1+~this.seed:this.seed)%1e3/1e3}random_num(e,o){return e+(o-e)*this.random_dec()}random_int(e,o){return Math.floor(this.random_num(e,o))}}function average(e,o,t){return e/(o+1)*(t+1)}function pos(e){const o=average(600,7,e);return map(o,0,600,-ss/2,ss/2)}function applyFeedbackTo(e){const o=e.get(1,1,e.width-2,e.height-2);e.image(o,-50,-50,e.width,e.height)}";

    //build token claimed mapping
    mapping(uint256 => bool) public _buildTokenClaimed;

    //tokenId to unique hash mapping
    mapping(uint256 => bytes32) public _tokenIdToHash;

    constructor(address arfes) ERC721("ARBOFIRE", "arfw") {
        _arfes = IERC721(arfes);
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _maxSupply = maxSupply;
    }

    function setScript(string memory script) external onlyOwner {
        _script = script;
    }

    function toggleBurningEnabled() external onlyOwner {
        _isBurningEnabled = !_isBurningEnabled;
    }

    function toggleMintingEnabled() external onlyOwner {
        _isMintingEnabled = !_isMintingEnabled;
    }

    function toggleClaimingEnabled() external onlyOwner {
        _isClaimingEnabled = !_isClaimingEnabled;
    }

    function _mintToken(address to) internal {
        ++_tokenId;
        uint256 newTokenId = _tokenId;

        bytes32 hash = keccak256(
            abi.encodePacked(
                newTokenId,
                block.number,
                blockhash(block.number - 1),
                msg.sender,
                block.timestamp
            )
        );
        _tokenIdToHash[newTokenId] = hash;

        _safeMint(to, newTokenId);
    }

    function reserveTokens(uint256 tokensToReserve) external onlyOwner {
        for (uint256 i = 0; i < tokensToReserve; i++) {
            _mintToken(msg.sender);
        }
    }

    function claim(uint256 buildTokenId) external {
        require(_isClaimingEnabled, "claiming is not enabled");
        require(totalSupply() < _maxSupply, "sold out");
        require(
            buildTokenId >= 357 && buildTokenId <= 536,
            "token ID entered is not a BUILD token"
        );
        require(
            _arfes.ownerOf(buildTokenId) == msg.sender,
            "not the owner of the BUILD token entered"
        );
        require(
            _buildTokenClaimed[buildTokenId] == false,
            "Firework already claimed for this BUILD token"
        );

        _buildTokenClaimed[buildTokenId] = true;
        _mintToken(msg.sender);
    }

    function mint() external payable {
        require(_isMintingEnabled, "minting is not enabled");
        require(totalSupply() < _maxSupply, "sold out");
        require(msg.value == PRICE_PER_TOKEN, "wrong value");

        _mintToken(msg.sender);
    }

    function burn(uint256 tokenId) public {
        require(_isBurningEnabled, "burning is not enabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        _abar.transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI_ = newBaseURI;
    }
}
