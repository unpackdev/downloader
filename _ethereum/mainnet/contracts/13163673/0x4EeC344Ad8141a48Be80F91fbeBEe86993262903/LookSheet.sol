// SPDX-License-Identifier: MIT

//  _                 _     _____ _               _   
// | |               | |   / ____| |             | |  
// | |     ___   ___ | | _| (___ | |__   ___  ___| |_ 
// | |    / _ \ / _ \| |/ /\___ \| '_ \ / _ \/ _ \ __|
// | |___| (_) | (_) |   < ____) | | | |  __/  __/ |_ 
// |______\___/ \___/|_|\_\_____/|_| |_|\___|\___|\__|

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract LookSheet is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _tokenIdsOwner;

    function getArmLength(uint256 tokenId) 
        public 
        pure 
        returns (string memory) 
    {
        return pluck(tokenId, "Arm Length", 10, 100, "cm");
    }

    function getLegLength(uint256 tokenId) 
        public 
        pure 
        returns (string memory) 
    {
        return pluck(tokenId, "Leg Length", 10, 150, "cm");
    }

    function getHeadLength(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        return pluck(tokenId, "Head Length", 10, 50, "cm");
    }

    function getTorsoLength(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        return pluck(tokenId, "Torso Length", 30, 100, "cm");
    }

    function getChestCircumference(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        return pluck(tokenId, "Chest Circumference", 50, 150, "cm");
    }

    function getWaistCircumference(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        return pluck(tokenId, "Waist Circumference", 50, 150, "cm");
    }

    function getSexAppeal(uint256 tokenId) public pure returns (string memory) {
        return pluck(tokenId, "Sex Appeal", 1, 20, "rawr");
    }

    // mirror a dice roll
    function random(string memory input, uint256 diff)
        internal
        pure
        returns (uint256)
    {
        return (uint256(keccak256(abi.encodePacked(input))) % diff) + 1;
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 floor,
        uint256 ceiling,
        string memory unit
    ) internal pure returns (string memory) {
        uint256 diff = ceiling - floor;
        string memory seedString = string(
            abi.encodePacked(keyPrefix, toString(tokenId))
        );

        uint256 stat = random(seedString, diff) + floor;

        string memory output = string(
            abi.encodePacked(keyPrefix, ": ", toString(stat), " ", unit)
        );

        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string[15] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#000000" /><text x="10" y="20" class="base">';

        parts[1] = getHeadLength(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getTorsoLength(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getLegLength(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getArmLength(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getChestCircumference(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getWaistCircumference(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getSexAppeal(tokenId);

        parts[14] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "LookSheet #',
                        toString(tokenId),
                        '", "description": "LookSheet are randomized RPG style character physical appearance stats generated and stored on chain. Feel free to use LookSheet in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function claim() public nonReentrant {
        // public starts from 1 to 9700. increments after checking.
        require(_tokenIds.current() < 9700, "Sorry, we run out of LookSheets. #9700 - 10000 are reserved for the team");

        _tokenIds.increment();
        _safeMint(_msgSender(), _tokenIds.current());
    }

    function teamClaim() public nonReentrant onlyOwner {
        // start owner on 9701. increments after checking.

        if (_tokenIdsOwner.current() < 9700) {
            _tokenIdsOwner._value = 9700;
        }
        require(_tokenIdsOwner.current() < 10000, "No more bro");

        _tokenIdsOwner.increment();
        _safeMint(owner(), _tokenIdsOwner.current());
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

    constructor() ERC721("LookSheet", "LOOKSHEET") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
