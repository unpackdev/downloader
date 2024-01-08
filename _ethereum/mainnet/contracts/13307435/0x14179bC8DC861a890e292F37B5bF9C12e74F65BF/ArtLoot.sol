/*
    ArtLoot is where abstract Art is stored on-chain and has API for everybody to use.
    This is the first collection of Abstract Landscapes.
    Feel free to use those landscapes in any way you wish.
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";
import "./Counters.sol";


contract ArtLootLandscapes is ERC721, ReentrancyGuard, Ownable {

        uint internal _presaleSupply = 0;
        uint internal _saleSupply = 0;
        uint internal alPrice = 20000000000000000; //0.02 eth
        uint internal maxPurchase = 10;
        bool public publicSale = false;
        bool public preSale = false;
        uint internal _maxPresale = 222;
        uint internal _maxSale = 2000;

        using Counters for Counters.Counter;
        Counters.Counter private _tokenIds;

        uint256 public MIN_COLORS = 2;
        uint256 public DELTA = 5; 

        mapping (uint256 => uint256) colorsSubstr;
        mapping (uint256 => uint256) colorsAdd;
        mapping(address => bool) private accessList;

    string[] private hexNums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];
    
    // Access
    modifier onlyAccess() {
        require(accessList[_msgSender()] == true, "Access not permitted");
        _;
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getColorsNum(uint256 tokenId, address checkAddr) public view returns (uint256) {
        require(_exists(tokenId), "!Token");
        uint256 numColors = random(string(abi.encodePacked("COLOR", toString(tokenId), checkAddr))) % DELTA + MIN_COLORS - colorsSubstr[tokenId] + colorsAdd[tokenId];
        if (numColors < 2) {
            return 2;
        }
        else if (numColors > 7) {
            return 7;
        } else {
            return numColors;
        }      
    }

    function getOneColor(uint256 tokenId, uint256 salt, address checkAddr) public view returns (uint256[] memory color) {
        require(_exists(tokenId), "!Token");
        color = new uint256[](6);
        uint256 rand = random(string(abi.encodePacked(salt, toString(tokenId), checkAddr)));
        for (uint256 i = 0; i < 6; i++) {
            color[i] = uint256(keccak256(abi.encode(rand, i))) % 16;
        }
        return color;
    }

    function getColors(uint256 tokenId, address checkAddr) public view returns (uint256[][] memory colors) {
        require(_exists(tokenId), "!Token");
        uint256 colorsNum = getColorsNum(tokenId, checkAddr);
        colors = new uint256[][](colorsNum);
        for (uint256 i = 0; i < colorsNum; i++) {
            colors[i] = getOneColor(tokenId, i, checkAddr);
        }
        return colors;
    }

    function getColorsString(uint256 tokenId, address checkAddr) public view returns (string[] memory colorsString) {
        uint256 colorsNum = getColorsNum(tokenId, checkAddr);
        colorsString = new string[](colorsNum);
        for (uint256 i = 0; i < colorsNum; i++) {
            colorsString[i] = getOneColorString(getOneColor(tokenId, i, checkAddr));
        }
        return colorsString;
    }

    function getOneColorString(uint256[] memory color) public view returns (string memory colorString) {  
        colorString = "#";
        for (uint256 i = 0; i < color.length; i++) {
            colorString = string(abi.encodePacked(colorString, hexNums[color[i]]));
        }
        return colorString;
    }

    function getColorSizes(uint256 tokenId, address checkAddr) public view returns (uint256[] memory sizes) { 
        uint256 colorsNum = getColorsNum(tokenId, checkAddr);
        uint256 totalSize = 0;
        for (uint256 i = 0; i < colorsNum; i++) {
            totalSize += sumArray(getOneColor(tokenId, i, checkAddr));
        }
        sizes = new uint[](colorsNum);
        for (uint256 i = 0; i < colorsNum; i++) {
            sizes[i] = sumArray(getOneColor(tokenId, i, checkAddr)) * 1000 / totalSize;    
        }
        return sizes;
    }

    function invertColor(uint256[] memory color) public pure returns (uint256[] memory invColor) {        
        invColor = new uint256[](color.length);
        for (uint256 i = 0; i < color.length; i++) {
            invColor[i] = 15 - color[i];
        } 
    }

    function sumArray(uint256[] memory array) internal pure returns (uint256) { 
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];    
        }
        return sum;
    }

    function tokenURIFor(uint256 tokenId, address checkAddr) public view returns (string memory) {

        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1000 1000"> <rect width="100%" height="100%" fill="black" /> <style>.base { font-family: monospace; font-size: 30px;}</style>';

        uint256 colorsNum = getColorsNum(tokenId, checkAddr);
        uint256 yStart = 0;
        uint256[] memory sizes = getColorSizes(tokenId, checkAddr);
        string[] memory colorsString = getColorsString(tokenId, checkAddr);

        for (uint256 i = 0; i < colorsNum; i++) {
            uint256 size = sizes[i];
            if (i==(colorsNum-1)) {
                size = 1000 - yStart;
            }
            string memory rect = string(abi.encodePacked(' <rect x="0" y="', toString(yStart) ,'" width="100%" height="', toString(size) ,'" fill="', colorsString[i],'"/>'));
            yStart += size;
            svg = string(abi.encodePacked(svg, rect));
        } 

        svg = string(abi.encodePacked(svg, '</svg>'));
        
        string memory json = string(abi.encodePacked('{"name": "ArtLoot Landscape #', toString(tokenId), '", "description": "ArtLoot is where abstract Art is stored on-chain", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",'));
        string memory json_attr1 =  string(abi.encodePacked(json, '"attributes": [{"trait_type": "Colors", "value": "',toString(getColorsNum(tokenId, checkAddr)), '"}'));
        string memory json_attr2; 
        for (uint i=1; i <= colorsNum; i++) {
            json_attr2 = string(abi.encodePacked(json_attr2, ', {"trait_type": "Color #', toString(i),'", "value": "',colorsString[i-1], '"}'));
        }
        string memory json_attr_b64 = Base64.encode(bytes(string(abi.encodePacked(json_attr1, json_attr2, ']}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json_attr_b64));
        
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return tokenURIFor(tokenId, ownerOf(tokenId));
    }

    function freeClaim() public nonReentrant {
        require(preSale, "presale not started");
        require(_presaleSupply + 1 <= _maxPresale, "presaleover");
        
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        _presaleSupply++;
    }

    function claim(uint256 _alQty) public payable nonReentrant {
        require(publicSale, "Sale not started");
        require(_alQty <= maxPurchase, "MaxPurch");
        require(_saleSupply + _alQty <= _maxSale, "MaxSupply");
        uint256 salePrice = _alQty*alPrice;
        require(msg.value >= salePrice, "low eth");

        for (uint256 i = 0; i < _alQty; i++) {
            _tokenIds.increment(); 
            uint256 newItemId = _tokenIds.current();
            _safeMint(_msgSender(), newItemId);
            _saleSupply++;
        }
    }

    function adminClaim(uint256 _alQty, address _to) onlyOwner
	public 
    {
        require(_saleSupply + _alQty <= _maxSale, "MaxSupply");
        for (uint256 i = 0; i < _alQty; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(_to, newItemId);
            _saleSupply++;
        }                        
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = totalSupply();
            uint256 resultIndex = 0;

            uint256 NFTId;

            for (NFTId = 1; NFTId <= totalNFTs; NFTId++) {
                if (ownerOf(NFTId) == _owner) {
                    result[resultIndex] = NFTId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function switchSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function switchPresale() external onlyOwner {
        preSale = !preSale;
    }

    function grantAccess(address _newAccesser) public onlyOwner {
        accessList[_newAccesser] = true;
    }

    function addColor(uint256 tokenId) public onlyAccess {
        colorsAdd[tokenId] += 1;
    }

    function substrColor(uint256 tokenId) public onlyAccess {
        colorsSubstr[tokenId] += 1;
    }

    // Get total Supply
    function totalSupply() public view returns (uint) {
        return _presaleSupply + _saleSupply;
    } 

    // Get current price
    function getPrice() public view returns (uint) {
        return alPrice;
    }

    // Get maximum allowance
    function getMax() public view returns (uint) {
        return maxPurchase;
    }

    // Set price
    function setPrice(uint _newPrice) public onlyOwner {
        alPrice = _newPrice;
    }

    // Set max
    function setMaxPurch(uint _newMax) public onlyOwner {
        maxPurchase = _newMax;
    }

    // Set presale amount
    function setMaxPresale(uint _newMax) public onlyOwner {
        _maxPresale = _newMax;
    }

    // Set sale amount
    function setMaxSale(uint _newMax) public onlyOwner {
        _maxSale = _newMax;
    }

    //withdraw
    function withdraw(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
    
    constructor() ERC721("AL Landscapes", "ALNDSCPS") Ownable() {}
}
