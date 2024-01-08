// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Binaries is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    using Strings for uint256;
    
    uint256 public tokenPrice = 10000000000000000; // 0.01 Ether
        
    string[] private commonNibbles = [
        "0001",
        "0010",
        "0011",
        "0100",
        "0101",
        "0110",
        "1000",
        "1001",
        "1010",
        "1100"
    ];

    string[] private rareNibbles = [
        "0111",
        "1011",
        "1101",
        "1110"
    ];
    
    string[] private legendaryNibbles = [
        "0000",
        "1111"
    ];


    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirstNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIRST", commonNibbles);
    }

    function getSecondNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SECOND", commonNibbles);
    }

    function getThirdNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "THIRD", commonNibbles);
    }

    function getFourthNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOURTH", commonNibbles);
    }

    function getFifthNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIFTH", commonNibbles);
    }

    function getSixthNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SIXTH", commonNibbles);
    }

    function getSeventhNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SEVENTH", commonNibbles);
    }

    function getEighthNibble(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "EIGHTH", commonNibbles);
    }

    function getAllBits(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(getFirstNibble(tokenId), getSecondNibble(tokenId), getThirdNibble(tokenId), getFourthNibble(tokenId), 
                                    getFifthNibble(tokenId), getSixthNibble(tokenId), getSeventhNibble(tokenId), getEighthNibble(tokenId)));
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, tokenId.toString())));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 karma = rand % 21;
        if (karma > 14) {
            output = rareNibbles[rand % rareNibbles.length];
        }
        if (karma == 19) {
            output = legendaryNibbles[rand % legendaryNibbles.length];
        }
        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[17] memory parts;
        
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: courier; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getFirstNibble(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getSecondNibble(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getThirdNibble(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getFourthNibble(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFifthNibble(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getSixthNibble(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getSeventhNibble(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getEighthNibble(tokenId);

        parts[16] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Binaries #', tokenId.toString(), '", "description": "Binaries are randomized bits generated and stored on chain. Functionalities are abstracted further to offer more room for interpretations; not bound by words or specific numbers. Feel free to use #Binaries in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function mintBinaries(uint256 tokenId) public nonReentrant payable{
        require(tokenId > 0 && tokenId < 8643, "Token ID invalid");
        require(msg.value >= tokenPrice, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 0 && tokenId < 8643, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
         
    function setPrice(uint256 _newPrice) public onlyOwner() {
        tokenPrice = _newPrice;
    }


    constructor() ERC721("Binaries", "BIN") Ownable() {}
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