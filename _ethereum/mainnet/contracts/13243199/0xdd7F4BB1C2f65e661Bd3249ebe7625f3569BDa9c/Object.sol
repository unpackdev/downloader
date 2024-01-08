// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Object is ERC721Enumerable, ReentrancyGuard, Ownable {

    string[] private power = [
        "10",
        "20",
        "30",
        "40",
        "50",
        "60",
        "70",
        "80",
        "90",
        "100"
    ];
    
    string[] private luck = [
        "10",
        "20",
        "30",
        "40",
        "50",
        "60",
        "70",
        "80",
        "90",
        "100"
    ];
    
    // Cooldown (weeks)
    string[] private cooldown = [
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "10",
        "11",
        "12"
    ];

    string[] private affinity = [
        "Red", 
        "Yellow", 
        "Green", 
        "Blue", 
        "Violet" 
    ];
    
    string[] private sigil = [
        "Wolf", 
        "Lion", 
        "Eagle", 
        "Stag", 
        "Bear"
    ];
    
    string[] private levels = [
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "10"
    ];

    // Activation Time (days)
    string[] private activation = [
        "1",
        "2",
        "3",
        "4",
        "5"
    ];
    
    // Volume
    string[] private volume = [
        "10",
        "20",
        "30",
        "40",
        "50",
        "60",
        "70",
        "80",
        "90",
        "100"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getPower(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "POWER", power);
    }
    
    function getLuck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LUCK", luck);
    }
    
    function getCooldown(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "COOLDOWN", cooldown);
    }
    
    function getAffinity(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "AFFINITY", affinity);
    }

    function getSigil(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SIGIL", sigil);
    }
    
    function getLevels(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LEVELS", levels);
    }
    
    function getActivation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ACTIVATION", activation);
    }
    
    function getVolume(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "VOLUME", volume);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId), msg.sender, tx.gasprice)));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }   

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: "Helvetica"; font-size: 16px; }</style><defs><radialGradient id="RadialGradient2" cx="-0.1" cy="-0.1" r="0.85"><stop offset="50%" stop-color="purple"/><stop offset="100%" stop-color="black"/></radialGradient></defs>><rect width="100%" height="100%" fill="url(#RadialGradient2)"/><text x="20" y="30" class="base">Power - ';
    
        parts[1] = getPower(tokenId);

        parts[2] = '</text><text x="20" y="50" class="base">Luck - ';

        parts[3] = getLuck(tokenId);

        parts[4] = '</text><text x="20" y="70" class="base">Cooldown - ';

        parts[5] = getCooldown(tokenId);

        parts[6] = ' week(s)</text><text x="20" y="90" class="base">Affinity - ';

        parts[7] = getAffinity(tokenId);

        parts[8] = '</text><text x="20" y="110" class="base">Sigil - ';

        parts[9] = getSigil(tokenId);

        parts[10] = '</text><text x="20" y="130" class="base">Levels - ';

        parts[11] = getLevels(tokenId);

        parts[12] = '</text><text x="20" y="150" class="base">Activation - ';

        parts[13] = getActivation(tokenId);

        parts[14] = ' day(s)</text><text x="20" y="170" class="base">Volume - ';

        parts[15] = getVolume(tokenId);
        
        parts[16] = '</text><text x="132" y="275" class="base" style="font-size: 10px; letter-spacing: 1.5; fill: purple">The Alchemist\'s</text><text x="117" y="300" class="base" style="font-size: 20px; letter-spacing: 5;">GLIMMER</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        // attributes: [{"trait_type": "Power", "value": "', getWeapon(tokenId), '"}, {"trait_type": "Luck", "value": "', getChest(tokenId), '"}, {"trait_type": "Cooldown", "value": "', getHead(tokenId), '"}, {"trait_type": "Affinity", "value": "', getWaist(tokenId), '"}, {"trait_type": "Sign", "value": "', getFoot(tokenId), '"}, {"trait_type": "Levels", "value": "', getHand(tokenId), '"}, {"trait_type": "Activation", "value": "', getNeck(tokenId), '"}, {"trait_type": "Charge", "value": "', getRing(tokenId), '"}]
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Object #', toString(tokenId), '", "description": "Why hello there, Moon Boy. It seems that you have found my Glimmer.", "external_url": "https://www.ritualmill.com/", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 5778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 5777 && tokenId < 6001, "Token ID invalid");
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
    
    constructor() ERC721("Digital Object", "OBJECT") Ownable() {}
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