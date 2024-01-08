// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./console.sol";

contract Dice is ERC721Enumerable, ReentrancyGuard, Ownable {

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "First");
    }
    function getSecond(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "Second");
    }
    function getThird(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "Third");
    }
    function getFourth(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "Fourth");
    }
    function getFifth(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "Fifth");
    }
    function getSixth(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "Sixth");
    }

    function pluck(uint256 tokenId, string memory keyPrefix) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint256 output = rand % 100;
        uint256 luck = rand % 21;
        if (luck < 3) {
          output /= 2;
        }
        if (luck >= 19) {
          output *= 2;
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        uint256[8] memory nums;
        nums[0] = getFirst(tokenId);
        nums[1] = getSecond(tokenId);
        nums[2] = getThird(tokenId);
        nums[3] = getFourth(tokenId);
        nums[4] = getFifth(tokenId);
        nums[5] = getSixth(tokenId);
        nums[6] = nums[0] + nums[1] + nums[2] + nums[3] + nums[4] + nums[5];
        nums[0] = 100 * nums[0]/nums[6];
        nums[1] = 100 * nums[1]/nums[6];
        nums[2] = 100 * nums[2]/nums[6];
        nums[3] = 100 * nums[3]/nums[6];
        nums[4] = 100 * nums[4]/nums[6];
        nums[5] = 100 - (nums[0] + nums[1] + nums[2] + nums[3] + nums[4]);
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = toString(nums[0]);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = toString(nums[5]);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = toString(nums[2]);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = toString(nums[3]);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = toString(nums[4]);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = toString(nums[1]);

        parts[12] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Dice #', toString(tokenId), '", "description": "Dice is randomized weighted dice generated and stored on chain. Some dice are more fair, others are luckier. Dice was inspired by the Loot community.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 6601, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 6600 && tokenId < 6666, "Token ID invalid");
        _safeMint(owner(), tokenId);
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

    constructor() ERC721("Dice", "Dice") Ownable() {}
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
