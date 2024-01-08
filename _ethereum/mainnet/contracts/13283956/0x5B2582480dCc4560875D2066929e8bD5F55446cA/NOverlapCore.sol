// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./EnumerableSet.sol";
import "./NPassCore.sol";
import "./IN.sol";
import "./console.sol";

/**
 * @title NOverlap
 * NOverlap is based on N project's numbers
 *
 * @author Inspired by @Tsnark and @KnavETH
 */
contract NOverlapCore is NPassCore {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 constant N_MAX_TOKENID = 8888;
    uint256 constant NUMBER_COUNT = 8;
    uint256 constant DEFAULT_PRICE_N_WEI = 25000000000000000;
    uint256 constant DEFAULT_PRICE_OPEN_WEI = 50000000000000000;

    uint256 public nextOpenTokenId = N_MAX_TOKENID + 1;

    // Allow anybody to mint with an available N
    bool public fullyOpenMintMode = false;

    string[9] paletteNames = [
        "Impossible",
        "Single",
        "Gold",
        "Silver",
        "Zombie",
        "Greenish",
        "Bluesky",
        "Fierce",
        "Uniques"
    ];
    mapping(uint256 => string[8]) colorPalettes;

    string[8] spiralCoordinates = [
        "-0.93%, -0.93%",
        "0.18%, -1.11%",
        "0.84%, -0.43%",
        "0.67%, 0.34%",
        "0.09%, 0.56%",
        "-0.27%, 0.27%",
        "-0.19%, -0.03%",
        "0%, 0%"
    ];

    constructor(address _nContractAddress)
        NPassCore(
            "NOverlap",
            "OVER",
            IN(_nContractAddress),
            false,
            9999,
            0,
            DEFAULT_PRICE_N_WEI,
            DEFAULT_PRICE_OPEN_WEI
        )
    {
        // Impossible Zoo
        colorPalettes[0] = [
            "F09828B0",
            "F06A76B0",
            "EE161FB0",
            "AE7A32B0",
            "FFF200B0",
            "35B548B0",
            "FF0A9DB0",
            "00AEEDB0"
        ];
        // Single - Pastel
        colorPalettes[1] = [
            "ffadadB0",
            "ffd6a5B0",
            "fdffb6B0",
            "caffbfB0",
            "9bf6ffB0",
            "a0c4ffB0",
            "bdb2ffB0",
            "ffc6ffB0"
        ];
        // Gold
        colorPalettes[2] = [
            "ff7b00B0",
            "ff8800B0",
            "ff9500B0",
            "ffa200B0",
            "ffaa00B0",
            "ffb700B0",
            "ffc300B0",
            "ffd000B0"
        ];
        // Silver
        colorPalettes[3] = [
            "edf2fb90",
            "e2eafc90",
            "d7e3fc90",
            "ccdbfd90",
            "c1d3fe90",
            "b6ccfe90",
            "abc4ff90",
            "edf2fb90"
        ];
        // Zombie
        colorPalettes[4] = [
            "606c38B0",
            "6b705cB0",
            "fefae0B0",
            "bc6c25B0",
            "dda15eB0",
            "6b705cB0",
            "bc6c25B0",
            "fefae0B0"
        ];
        // Greenish
        colorPalettes[5] = [
            "edf2fb90",
            "2B784FB0",
            "8BD0B4B0",
            "69C996B0",
            "E8EDE8A0",
            "70E000B0",
            "2AB74DB0",
            "88D4ABB0"
        ];
        // Bluesky
        colorPalettes[6] = [
            "0077b6B0",
            "00b4d8B0",
            "90e0efB0",
            "0077b6B0",
            "00b4d8B0",
            "90e0efB0",
            "0077b6B0",
            "00b4d8B0"
        ];
        // Fierce
        colorPalettes[7] = [
            "800f2fB0",
            "a4133cB0",
            "c9184aB0",
            "ff4d6dB0",
            "ba181bB0",
            "ef233cB0",
            "d90429B0",
            "ff4d6dB0"
        ];
        // Uniques
        colorPalettes[8] = [
            "06d6a0B0",
            "fb5607B0",
            "ff006eB0",
            "3a86ffB0",
            "8338ecB0",
            "aacc00B0",
            "C11CADB0",
            "ffbe0bB0"
        ];
    }

    string constant SVG_FRAGMENT_START =
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 600 600">';
    string constant SVG_FRAGMENT_RECT = '<rect width="100%" height="100%" fill="#293241" />';
    string constant SVG_FRAGMENT_END = "</svg>";

    string[8] openPrefixes = [
        "OPENFIR",
        "OPENSECODN",
        "OPENTHR",
        "OPENFFF",
        "OPENFIF",
        "OPENSIX",
        "OPENSEVENUP",
        "OPENHIHGH"
    ];

    ///
    /// VIEW
    ///

    /**
     * for tokenId <= 8888, get the number from the underlying n
     * for tokenId > 8888, internal pluck
     */
    function getNumber(uint256 tokenId, uint256 index) public view virtual returns (uint256 number) {
        if (tokenId > N_MAX_TOKENID) {
            return pluck(tokenId, openPrefixes[index - 1], units);
        } else {
            if (index == 1) {
                number = n.getFirst(tokenId);
            }
            if (index == 2) {
                number = n.getSecond(tokenId);
            }
            if (index == 3) {
                number = n.getThird(tokenId);
            }
            if (index == 4) {
                number = n.getFourth(tokenId);
            }
            if (index == 5) {
                number = n.getFifth(tokenId);
            }
            if (index == 6) {
                number = n.getSixth(tokenId);
            }
            if (index == 7) {
                number = n.getSeventh(tokenId);
            }
            if (index == 8) {
                number = n.getEight(tokenId);
            }
        }
    }

    function arrayContains(uint256[8] memory ar, uint256 n) public pure returns (bool) {
        for (uint256 i = 0; i < ar.length; i++) {
            if (ar[i] == n) {
                return true;
            }
        }
        return false;
    }

    function computeUniqueCount(uint256 tokenId) public view returns (uint256) {
        uint256[8] memory uniqueNumbers;
        uint256 uniqueCount = 0;
        for (uint8 i = 1; i <= NUMBER_COUNT; i++) {
            uint256 number = getNumber(tokenId, i);
            if (!arrayContains(uniqueNumbers, number)) {
                uniqueNumbers[uniqueCount] = number;
                uniqueCount++;
            }
        }
        console.log("uniqueCount %s", uniqueCount);
        return uniqueCount;
    }

    function textFragment(uint256 number, uint256 colorIndex) internal pure returns (string memory) {
        string[5] memory p;
        p[0] = '<text x="300" y="370" textLength="400" class="base c';
        p[1] = toString(colorIndex);
        p[2] = '">';
        p[3] = toString(number);
        p[4] = "</text>";
        string memory output = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4]));
        return output;
    }

    function shouldRotate(uint256 tokenId) internal view returns (bool) {
        return rotateAngle(tokenId, 1) != 0;
    }

    /**
     * Rotation applied if n3 > 10
     * Angle is n3 * n4
     */
    function rotateAngle(uint256 tokenId, uint256 numberIndex) internal view returns (uint256 angle) {
        if (getNumber(tokenId, 3) > 10) {
            angle = getNumber(tokenId, 3) * getNumber(tokenId, 4) * numberIndex;
        } else {
            angle = 0;
        }
        return angle;
    }

    function closeBracketAndRotateString(uint256 tokenId, uint256 numberIndex) internal view returns (string memory) {
        string[3] memory r;
        r[0] = ") rotate(";
        r[1] = toString(rotateAngle(tokenId, numberIndex));
        r[2] = "deg)";
        return string(abi.encodePacked(r[0], r[1], r[2]));
    }

    function computeStyles(uint256 tokenId, uint256 uniqueCount) internal view returns (string memory styles) {
        string[10] memory s;
        s[
            0
        ] = "<style> .base { fill: white; font-family: serif; font-size: 750px; text-anchor: middle; dominant-baseline: middle;}";
        // Throw in some randomness on a lucky number
        uint256 luckyNumberIndex = (getNumber(tokenId, 1) % 8) + 1;
        uint256 luckyPaletteIndex = getNumber(tokenId, 2) % 9;
        uint256 luckyColorIndex = getNumber(tokenId, 3) % 8;
        console.log("lucky numbers %s %s %s", luckyNumberIndex, luckyPaletteIndex, luckyColorIndex);
        // s[1] to s[8]
        for (uint8 i = 1; i <= NUMBER_COUNT; i++) {
            string[8] memory c;
            c[0] = " .c";
            c[1] = toString(i);
            c[2] = " {fill: #";
            if (luckyNumberIndex == i) {
                // lucky color
                c[3] = colorPalettes[luckyPaletteIndex][luckyColorIndex];
            } else {
                // palette starting index in n5 % 8
                uint256 colorIndex = (getNumber(tokenId, 5) + i - 1) % 8;
                c[3] = colorPalettes[uniqueCount][colorIndex];
            }
            c[4] = "; transform: translate(";
            c[5] = spiralCoordinates[i - 1];
            if (shouldRotate(tokenId)) {
                c[6] = closeBracketAndRotateString(tokenId, i);
            } else {
                c[6] = ")";
            }
            c[7] = "; transform-origin: 50% 50%;}";
            s[i] = string(abi.encodePacked(c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7]));
        }
        s[9] = "</style>";
        styles = string(abi.encodePacked(s[0], s[1], s[2], s[3], s[4], s[5], s[6]));
        styles = string(abi.encodePacked(styles, s[7], s[8], s[9]));
        return styles;
    }

    function tokenSVG(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 uniqueCount = computeUniqueCount(tokenId);
        return _tokenSVG(tokenId, uniqueCount);
    }

    function _tokenSVG(uint256 tokenId, uint256 uniqueCount) internal view virtual returns (string memory) {
        string[12] memory parts;
        parts[0] = SVG_FRAGMENT_START;
        parts[1] = computeStyles(tokenId, uniqueCount);
        parts[2] = SVG_FRAGMENT_RECT;
        uint256 offset = 2;
        // part 3-10
        for (uint8 i = 1; i <= NUMBER_COUNT; i++) {
            parts[i + offset] = textFragment(getNumber(tokenId, i), i);
        }
        parts[11] = SVG_FRAGMENT_END;

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6])
        );
        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9], parts[10], parts[11]));
        return output;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory output) {
        console.log("tokenURI for %s", tokenId);
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 uniques = computeUniqueCount(tokenId);
        output = _tokenSVG(tokenId, uniques);
        bool rotated = shouldRotate(tokenId);
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "noverlap #',
                        toString(tokenId),
                        '", "tokenId": "',
                        toString(tokenId),
                        '", "description": "number overlap is just overlapped numbers", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": [{"trait_type": "uniques", "value": "',
                        toString(uniques),
                        '"}, {"trait_type": "palette", "value": "',
                        paletteNames[uniques],
                        '"}, {"trait_type": "rotated", "value": "',
                        rotated ? "true" : "false",
                        '"}]}'
                    )
                )
            )
        );
        // reuse output for optimization?
        output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }

    ///
    /// MINT
    ///

    /**
     * Mint the next available token in the open range 8889 to 9999
     */
    function mintNextOpen() public payable virtual {
        require(nextOpenTokenId <= maxTotalSupply, "NOverlap: Open supply is fully minted");
        mint(nextOpenTokenId);
        nextOpenTokenId++;
    }

    /**
     * Mint without N
     * @param tokenId Id to be minted
     */
    function mint(uint256 tokenId) public payable override nonReentrant {
        console.log("Trying to mint %s", tokenId);
        require(tokenId <= maxTotalSupply, "NOverlap: Open supply is fully minted");
        require(!onlyNHolders, "NPass:OPEN_MINTING_DISABLED");
        require(openMintsAvailable() > 0, "NPass:MAX_ALLOCATION_REACHED");
        require(
            (tokenId > MAX_N_TOKEN_ID && tokenId <= maxTokenId()) || n.ownerOf(tokenId) == msg.sender,
            "NPass:INVALID_ID"
        );
        require(msg.value >= priceForOpenMintInWei, "NPass:INVALID_PRICE");

        _safeMint(msg.sender, tokenId);
        emit Mint(msg.sender, tokenId);
    }

    /**
     * Mint with N
     * @notice Allow a n token holder to mint a token with one of their n token's id
     * @param tokenId Id to be minted
     */
    function mintWithN(uint256 tokenId) public payable override nonReentrant {
        console.log("Trying to mintWithN %s", tokenId);
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        // owners can mint
        if (!fullyOpenMintMode) {
            require(n.ownerOf(tokenId) == msg.sender, "NPass:INVALID_OWNER");
        }
        // lower price for owners
        if (n.ownerOf(tokenId) == msg.sender) {
            require(msg.value >= priceForNHoldersInWei, "NPass:INVALID_PRICE");
        } else {
            require(msg.value >= priceForOpenMintInWei, "NPass:INVALID_PRICE");
        }
        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }
        _safeMint(msg.sender, tokenId);
        emit Mint(msg.sender, tokenId);
    }

    function setNextOpenTokenId(uint256 _nextOpenTokenId) public onlyOwner {
        nextOpenTokenId = _nextOpenTokenId;
    }

    function setFullyOpenMintMode(bool _fullOpen) public onlyOwner {
        fullyOpenMintMode = _fullOpen;
    }

    // fallback functions
    fallback() external payable {}

    receive() external payable {}

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

    // For Tokens above 8888

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

    uint8[] private suffixes = [1, 2];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
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
