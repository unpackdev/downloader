// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NPass.sol";

contract NColor is NPass {
    uint8[] private units = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10
    ];

    uint8[] private multipliers = [
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        0
    ];

    address t1 = 0x069e85D4F1010DD961897dC8C095FBB5FF297434; // Dunks
    address t2 = 0x4Ee34BA6c5707f37C8367fd8AEF43F754435F588; // 0xkowloon
    address t3 = 0xbCA2eE79aBdDF13B7f51015f183a5758D718FC86; // journeyape
    address t4 = 0xDF8413C52e2D552DAdc7aDe05273c4b62dF51A2a; // multi-sig

    uint8[] private suffixes = [1, 2];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "FIRST", units);
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "SECOND", units);
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "THIRD", units);
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "FOURTH", units);
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "FIFTH", units);
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "SIXTH", units);
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "SEVENT", units);
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return pluck(tokenId, "EIGHT", units);
    }

    function getHexCode(uint256 tokenId) public view returns (string memory) {
        string[9] memory hexArray;
        hexArray[0] = "#";
        hexArray[1] = toHexString(getFirst(tokenId));
        hexArray[2] = toHexString(getSecond(tokenId));
        hexArray[3] = toHexString(getThird(tokenId));
        hexArray[4] = toHexString(getFourth(tokenId));
        hexArray[5] = toHexString(getFifth(tokenId));
        hexArray[6] = toHexString(getSixth(tokenId));
        hexArray[7] = toHexString(getSeventh(tokenId));
        hexArray[8] = toHexString(getEight(tokenId));

        return
            string(
                abi.encodePacked(
                    hexArray[0],
                    hexArray[1],
                    hexArray[2],
                    hexArray[3],
                    hexArray[4],
                    hexArray[5],
                    hexArray[6],
                    hexArray[7],
                    hexArray[8]
                )
            );
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint8[] memory sourceArray
    ) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint256 output = sourceArray[rand % sourceArray.length];
        uint256 luck = rand % 21;
        if (luck > 14) {
            output += suffixes[rand % suffixes.length];
        }
        if (luck >= 19) {
            if (luck == 19) {
                output = (output * multipliers[rand % multipliers.length]) + suffixes[rand % suffixes.length];
            } else {
                output = (output * multipliers[rand % multipliers.length]);
            }
        }

        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory hexCode = getHexCode(tokenId);

        string[5] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="';

        parts[1] = hexCode;

        parts[2] = '" /><text x="10" y="20" letter-spacing="12" class="base">';

        parts[3] = hexCode;

        parts[4] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "n Color #',
                        toString(tokenId),
                        '", "attributes": [{"trait_type": "hex", "value": "',
                        hexCode,
                        '"}], "description": "n Colors are generated using 8-digit hex notation and the RGBA color model.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function mintWithN(uint256 tokenId) public payable override nonReentrant {
        require(msg.value >= 0.01 ether, "NPass:MINTING_FEE_REQUIRED");
        require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        _safeMint(msg.sender, tokenId);
    }

    function mint(uint256 tokenId) public payable override nonReentrant {
        require(!onlyNHolders, "NPass:OPEN_MINTING_DISABLED");
        require(tokenId > MAX_N_TOKEN_ID && tokenId < 10000, "NPass:INVALID_ID");
        require(msg.value >= 0.02 ether, "NPass:MINTING_FEE_REQUIRED");

        _safeMint(msg.sender, tokenId);
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

    function toHexString(uint256 value) internal pure returns (string memory hexString) {
        if (value <= 9) {
            hexString = toString(value);
        } else if (value == 10) {
            hexString = "A";
        } else if (value == 11) {
            hexString = "B";
        } else if (value == 12) {
            hexString = "C";
        } else if (value == 13) {
            hexString = "D";
        } else if (value == 14) {
            hexString = "E";
        }
    }

    function withdrawAll() external payable onlyOwner {
        uint256 _each = address(this).balance / 4;
        (bool success1, ) = payable(t1).call{ value: _each }("");
        require(success1, "Transfer to t1 failed");
        (bool success2, ) = payable(t2).call{ value: _each }("");
        require(success2, "Transfer to t2 failed");
        (bool success3, ) = payable(t3).call{ value: _each }("");
        require(success3, "Transfer to t3 failed");
        (bool success4, ) = payable(t4).call{ value: _each }("");
        require(success4, "Transfer to t4 failed");
    }

    constructor() NPass("N COLORS", "NC", false) {}
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
