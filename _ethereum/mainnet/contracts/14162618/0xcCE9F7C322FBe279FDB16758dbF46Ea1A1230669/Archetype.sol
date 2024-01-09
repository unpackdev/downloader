// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Archetype is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public maxSupply = 5348;
    uint256 public price = 0.05 ether;
    uint256 public maxMint = 4;
    uint256 public numTokensMinted;
    uint256 public maxPerAddress = 4;
    mapping(address => uint256) private _mintPerAddress;

    string[] private archetypes = [
        "Wordcel",
        "Shape Rotator"
    ];

    string[] private shapes = [
        unicode"◰",
        unicode"◱",
        unicode"◲",
        unicode"◴",
        unicode"◶",
        unicode"◵",
        unicode"△",
        unicode"▷",
        unicode"▽",
        unicode"◯",
        unicode"◎",
        unicode"◻"
    ];

    string[] private alphabet = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
        "m",
        "n",
        "o",
        "p",
        "q",
        "r",
        "s",
        "t",
        "u",
        "v",
        "w",
        "x",
        "y",
        "z"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getArchetype(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "archetype", archetypes);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
 
        return output;
    }

    function getSuffix(uint256 tokenId) public view returns (string memory) {
        string memory archetype = getArchetype(tokenId);

        if (keccak256(abi.encodePacked((archetype))) == (keccak256(abi.encodePacked(('Wordcel'))))) {
            string memory one = pluck(tokenId, "FIRST", alphabet);
            string memory two = pluck(tokenId, "SECOND", alphabet);
            string memory three = pluck(tokenId, "THIRD", alphabet);

            return string(abi.encodePacked(one, two, three));
        } else {
            string memory one = pluck(tokenId, "FIRST", shapes);
            string memory two = pluck(tokenId, "SECOND", shapes);
            string memory three = pluck(tokenId, "THIRD", shapes);

            return string(abi.encodePacked(one, two, three));
        } 
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[6] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; }</style><rect width="100%" height="100%" fill="black" /><text font-size="42" text-anchor="middle" x="50%" y="50%" class="base">';

        parts[1] = getArchetype(tokenId);

        parts[2] = '</text>';

        parts[3] = '<text font-size="12" text-anchor="middle" x="90%" y="95%" class="base">';
        
        parts[4] = getSuffix(tokenId);

        parts[5] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Archetype #', toString(tokenId), '", "description": "Are you a wordcel or a shape rotator?", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function mint(uint256 amountOfTokens) external payable {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(_mintPerAddress[msg.sender] + amountOfTokens <= maxPerAddress, "You can't exceed this wallet's minting limit");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");
       
        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(_msgSender(), tokenId);
            numTokensMinted += 1;
            _mintPerAddress[msg.sender] += 1;
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
    
    constructor() ERC721("Wordcel Shape Rotator", "WSR") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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