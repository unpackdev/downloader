//SPDX-License-Identifier:MIT

pragma solidity>=0.4.25;
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
contract Hanzi is ERC721, Ownable{

    uint public totalSupply=0;
    constructor() ERC721("Chinese character","CC"){
    }
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"><style>.base { fill: black; font-family: serif; font-size: 200px; }</style><rect width="100%" height="100%" fill="white"/><text x="100" y="260" class="base">&#';
        parts[1] = Strings.toString(19967+tokenId);
        parts[2] = ';</text></svg>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Character #',Strings.toString(tokenId), '", "description": "Chinese characters are the essence of Chinese culture, and friends who like Chinese culture can have them. A total of 20,902 Chinese characters are distributed for free.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    function tokenUnicode(uint256 tokenId) public pure returns (string memory){
        return  Strings.toString(19967+tokenId);
    }

    function claim(uint256 tokenId) public  {
        totalSupply++;
        require(balanceOf(_msgSender())<100, "claim over 100");
        require(tokenId > 0 && tokenId < 18001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);

    }
    function ownerClaim(uint256 tokenId) public  onlyOwner {
        totalSupply++;
        require(tokenId > 18000 && tokenId < 20903, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
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