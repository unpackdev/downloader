// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./base64.sol";
import "./TreeGenerator.sol";

contract OnChainXmasTree is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply=4646;
    uint256 public price=0.025 ether;
    uint256 public tokenCounter=0;
    bool public sale = true;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < tokenCounter);

        TreeGenerator.xmasTree memory xt;
        string memory svg;
        (xt, svg) = TreeGenerator.getTreeForSeed(tokenId);

        string[9] memory treeColAttr = ['Leafy Green','Snow White','Golden Sizzle','Alien Blue','Merry Red','Pink Berry','Icy Blue','Gorgeous Grey','Autumn Love'];
        string[8] memory treeAttr = ['Zip Zap','Nacho','Flow-ey','Pixelated','Paper Cut','Pyramid','Thorn-y','Cone-y'];
        string[5] memory giftAttr = ['No','1 Gift','2 Gifts','3 Gifts','4 Gifts'];
        string[2] memory capAttr = ['No','Yes'];
        string[8] memory colsAttr = ['Silver','Red','Orange','Green','Blue','Yellow','Purple','No'];
        string[11] memory bgAttr = ['Sliver Clouds','Peachy Noon','Pink Dawn','Northern Lights','Morning Green','Lavender Dusk','Misty Blue','Stormy Grey','Arabian Night','Violet Night','Night Sky'];  

        string memory json = string(abi.encodePacked(
            '{"name" : "OCXT#',Strings.toString(tokenId),'",',
            '"description": "100% on-chain generative Christmas Trees for you to own or share and keep your traditions alive on the blockchain.",', 
            '"attributes":[',
            '{"trait_type":"Background","value":"',bgAttr[xt.bgCol],'"},',
            '{"trait_type":"Tree Type","value":"',treeAttr[xt.treeType],'"},'));
        json = string(abi.encodePacked(json,
            '{"trait_type":"Tree Color","value":"',treeColAttr[xt.treeCol],'"},',
            '{"trait_type":"Snow Cap","value":"',capAttr[xt.snowCap],'"},'));

        if (xt.star==0) {json = string(abi.encodePacked(json,'{"trait_type":"Star","value":"No"},','{"trait_type":"Santa Hat","value":"No"},'));}
        if (xt.star==1) {json = string(abi.encodePacked(json,'{"trait_type":"Star","value":"',colsAttr[xt.starCol],'"},','{"trait_type":"Santa Hat","value":"No"},'));}
        if (xt.star==2) {json = string(abi.encodePacked(json,'{"trait_type":"Star","value":"No"},','{"trait_type":"Santa Hat","value":"',colsAttr[xt.starCol],'"},'));}

        string memory bulbAni = '';
        if(xt.bulbAni) {bulbAni = ' Animated';}
        json = string(abi.encodePacked(json,
            '{"trait_type":"Clouds","value":"',capAttr[xt.cloud],'"},',
            '{"trait_type":"Ribbon","value":"',colsAttr[xt.ribbonCol],'"},',
            '{"trait_type":"Bulbs","value":"',colsAttr[xt.bulbCol],bulbAni,'"},',
            '{"trait_type":"Gifts","value":"',giftAttr[xt.gifts],'"}',
            '],'
            '"image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(svg)),
            '"}'
        ));
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function claim(address a, uint256 x) public payable nonReentrant {
        require(tokenCounter < maxSupply, "All tokens minted");
        require(sale, "Sales are paused");
        require(x < 11, "Max Limit");
        require(balanceOf(a)+x < 26, "Wallet limit reached");
        require(price*x <= msg.value, "Incorrect ETH amount");
        for(uint256 i=0; i<x; i++) {
            _safeMint(a, tokenCounter);
            tokenCounter++;
            sanity();
        }
    }

    function supply(uint256 a) public onlyOwner {
        maxSupply = a;
    }

    function priceMod(uint256 a) public onlyOwner {
        price = a;
    }

    function claimOwn(address a, uint256 b) public onlyOwner {
        for(uint256 i=0; i<b; i++) {
            _safeMint(a, tokenCounter);
            tokenCounter++;
            sanity();
        }
    }

    function saleToggle() public onlyOwner {
        sale = !sale;
    }

    function withdrawAll() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function sanity() internal {
        uint16[27] memory id = [41,81,157,386,766,855,991,1071,1125,1134,1497,1678,1801,1973,1981,2072,2471,2510,2564,2922,2965,2996,3347,3437,3696,3960,4990];
        for(uint16 i=0; i<id.length;i++) {
            if(tokenCounter==id[i]) {
                tokenCounter++;
            }
        }
    }

    constructor() ERC721('Christmas Trees by Traditions On Chain','OCXT') Ownable() { 
    }
}
    