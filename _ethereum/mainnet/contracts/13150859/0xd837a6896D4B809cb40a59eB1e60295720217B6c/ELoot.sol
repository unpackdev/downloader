// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25;

import "./ERC721.sol";
import "./Ownable.sol";
abstract contract  Loot {
    function getWeapon(uint256 tokenId) public view virtual returns (string memory);
    function getChest(uint256 tokenId) public view virtual returns (string memory) ;
    function getHead(uint256 tokenId) public view virtual returns (string memory) ;
    function getWaist(uint256 tokenId) public view virtual returns (string memory) ;
    function getFoot(uint256 tokenId) public view virtual returns (string memory) ;
    function getHand(uint256 tokenId) public view virtual returns (string memory) ;
    function getNeck(uint256 tokenId) public view virtual  returns (string memory) ;
    function getRing(uint256 tokenId) public view virtual  returns (string memory) ;
}
contract ELoot is ERC721, Ownable{
    uint public totalSupply=0;
    Loot loot = Loot(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    function getHealthy(uint256 tokenId) public pure returns (string memory) {
        return pluck(tokenId, "Healthy");
    }
    function getMagic(uint256 tokenId) public pure returns (string memory) {
        return pluck(tokenId, "Magic");
    }
    function getLeadership(uint256 tokenId) public pure returns (string memory) {
        return pluck(tokenId, "Leadership");
    }
    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return loot.getWeapon(tokenId);
    }
    function getChest(uint256 tokenId) public view returns (string memory) {
        return loot.getChest(tokenId);
    }
    function getHead(uint256 tokenId) public view returns (string memory) {
        return loot.getHead(tokenId);
    }
    function getWaist(uint256 tokenId) public view returns (string memory) {
        return loot.getWaist(tokenId);
    }
    function getFoot(uint256 tokenId) public view returns (string memory) {
        return loot.getFoot(tokenId);
    }
    function getHand(uint256 tokenId) public view returns (string memory) {
        return loot.getHand(tokenId);
    }
    function getNeck(uint256 tokenId) public view returns (string memory) {
        return loot.getNeck(tokenId);
    }
    function getRing(uint256 tokenId) public view returns (string memory) {
        return loot.getRing(tokenId);
    }
    function pluck(uint256 tokenId, string memory keyPrefix) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, tokenId)));
        uint256 greatness = rand % 21;
        string memory l = "C";
        if (greatness > 19) {
            l="S";
        }else if(greatness > 15){
            l="A";
        }else if(greatness > 5){
            l="B";
        }
        return string(abi.encodePacked(keyPrefix, " ", l));
    }
    function rowString( string memory parts, uint index) internal pure returns (string memory){
       return string(abi.encodePacked( '<text x="10" y="'  , toString(index*20) ,'" class="base">',parts,'</text>'));
    }
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[13] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = rowString( getWeapon(tokenId),1);
        parts[2] = rowString(getChest(tokenId),2);
        parts[3] = rowString(getHead(tokenId),3);
        parts[4] = rowString(getWaist(tokenId),4);
        parts[5] = rowString(getFoot(tokenId),5);
        parts[6] = rowString(getHand(tokenId),6);
        parts[7] = rowString(getNeck(tokenId),7);
        parts[8] = rowString(getRing(tokenId),8);
        parts[9] = rowString(getHealthy(tokenId),9);
        parts[10] = rowString(getMagic(tokenId),10);
        parts[11] = rowString(getLeadership(tokenId),11);
        parts[12] = '</svg>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #',toString(tokenId), '", "description": "Loot+ is randomized adventurer gear generated and stored on chain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    function claim() public  {
        totalSupply++;
        require(balanceOf(_msgSender())<3, "claim over 3");
        require(totalSupply > 0 && totalSupply < 7801, "Token ID invalid");
        _safeMint(_msgSender(), totalSupply);

    }
    function ownerClaim(uint256 tokenId) public  onlyOwner {
        totalSupply++;
        require(tokenId > 7800 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    function toString(uint256 value) internal pure returns (string memory) {
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
    constructor() ERC721("Loot plus", "Loot+") Ownable() {}
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}