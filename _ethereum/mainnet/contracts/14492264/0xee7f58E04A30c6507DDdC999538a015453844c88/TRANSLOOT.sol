/*
 *  _        _______  _______ _________
 * ( \      (  ___  )(  ___  )\__   __/
 * | (      | (   ) || (   ) |   ) (   
 * | |      | |   | || |   | |   | |   
 * | |      | |   | || |   | |   | |   
 * | |      | |   | || |   | |   | |   
 * | (____/\| (___) || (___) |   | |   
 * (_______/(_______)(_______)   )_(
 *
 *  ▄▄▄      ▄▄▄      ▄▄▄▄▄▄▄▄   ▄▄▄·  ▐ ▄ .▄▄ ·      ▄▄ • ▪  ▄▄▄  ▄▄▌  .▄▄ · 
 * ▐▄▄·▪     ▀▄ █·    •██  ▀▄ █·▐█ ▀█ •█▌▐█▐█ ▀.     ▐█ ▀ ▪██ ▀▄ █·██•  ▐█ ▀. 
 * ██▪  ▄█▀▄ ▐▀▀▄      ▐█.▪▐▀▀▄ ▄█▀▀█ ▐█▐▐▌▄▀▀▀█▄    ▄█ ▀█▄▐█·▐▀▀▄ ██▪  ▄▀▀▀█▄
 * ██▌.▐█▌.▐▌▐█•█▌     ▐█▌·▐█•█▌▐█ ▪▐▌██▐█▌▐█▄▪▐█    ▐█▄▪▐█▐█▌▐█•█▌▐█▌▐▌▐█▄▪▐█
 * ▀▀▀  ▀█▄▀▪.▀  ▀     ▀▀▀ .▀  ▀ ▀  ▀ ▀▀ █▪ ▀▀▀▀     ·▀▀▀▀ ▀▀▀.▀  ▀.▀▀▀  ▀▀▀▀ 
 *
 * 6969 fully on-chain starter kits
 *     a cc0 project by thorne
 */
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// SPDX-License-Identifier: CC0-1.0
contract TRANSLOOT is ERC721A, ReentrancyGuard, Ownable {
    constructor() ERC721A("Trans Loot", "TRANSLOOT") Ownable() {}

    uint256 public mintPrice = 0.01 ether;
    uint256 public constant maxTokens = 6969;

    // Estrogen Sources
    string[] private e = [
        "Titty Skittles",
        "Conjugated Estrogens",
        "Injectable Estradiol",
        "Transdermal Estradiol",
        "Bathtub Estrogen"
    ];

    // Testosterone Prevention
    string[] private antiT = [
        "Spironolactone",
        "Cyproterone",
        "Orchi",
        "Vaginoplasty"
    ];
    
    string[] private bodyOutfit = [
        "Kitty Kigurumi",
        "Corgi Kigurumi",
        "Bear Kigurumi",
        "Dino Kigurumi",
        "Against Me! T-Shirt",
        "Shinji T-Shirt",
        "Asuka T-Shirt",
        "Boymode Hoodie",
        "Pink Hoodie",
        "White Sun Dress (Go Spinny)",
        "Floral Sun Dress (Go Spinny)",
        "Slutty Black Dress (Go Spinny)",
        "Trans Flag T-Shirt"
    ];
    
    string[] private headOutfit = [
        "Kitty Ears",
        "Pupper Ears",
        "Miqo'te Ears",
        "Gaming Headset",
        "Beige Sun Hat",
        "Violet Sun Hat",
        "uwu Face Mask",
        "Anime Face Mask",
        "O-Ring Collar",
        "Heart Choker Collar"
    ];
    
    string[] private legs = [
        "Blue Striped Thigh-Highs",
        "Pink Striped Thigh-Highs",
        "Lavender Striped Thigh-Highs",
        "Yoga Pants",
        "Teal Skirt (Go Spinny)",
        "Lavender Skirt (Go Spinny)",
        "Black Skirt (Go Spinny)",
        "Gray Skirt (Go Spinny)",
        "Skinny Jeans",
        "Pink Pajama Pants",
        "Heart Pajama Pants",
        "Flower Pajama Pants"
    ];
    
    string[] private snacks = [
        "Pickles",
        "Popcorn",
        "Baja Blast",
        "Chicken Nuggies",
        "French Fries",
        "Takis",
        "Monster Zero Ultra",
        "Hi-Chew"
    ];
    
    string[] private games = [
        "Minecraft",
        "Fallout: New Vegas",
        "Stardew Valley",
        "Animal Crossing: New Horizons",
        "VRChat",
        "Final Fantasy VII",
        "Final Fantasy VII: Remake",
        "Hearts of Iron IV",
        "Civilization VI",
        "Cookie Clicker"
    ];
    
    string[] private politics = [
        "Tankie",
        "Normie Lib",
        "#BernieOrBust",
        "Medlock Sock",
        "Cypherpunk",
        "Anarcho-Syndicalist",
        "Pragmatic Progressive",
        "Georgist",
        "Warren Democrat"
    ];
    
    string[] private suffixes = [
        "of Peculiar Power",
        "of the Catgirl Clowder",
        "of the Weebs",
        "of the Rowlingless Coven",
        "of Boundless Hope",
        "of the Phoenix",
        "of the Ether",
        "of Being a Good Girl",
        "of Bottom Text"
        "of TERF Repulsion",
        "of Edgelord Blocking",
        "of Gatekeeper Evasion",
        "of the Endless Euphoria"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getE(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "E", e, true);
    }

    function getAntiT(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ANTI-T", antiT, true);
    }
    
    function getBody(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "BODY", bodyOutfit, true);
    }
    
    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", headOutfit, true);
    }

    function getLegs(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LEGS", legs, true);
    }
    
    function getSnack(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SNACK", snacks, true);
    }
    
    function getGame(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GAME", games, false);
    }
    
    function getPolitics(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "POLITICS", politics, false);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, bool decorate) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];

        if(decorate) {
            uint256 greatness = rand % 21;
            if (greatness > 14) {
                output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
            }
        }
        
        return output;
    }

    // Assemble both the SVG data and on-chain trait data
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        string[8] memory traits;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base" fill="#7ACBF5">';

        parts[1] = getE(tokenId);
        traits[0] = string(abi.encodePacked('{"trait_type":"E","value":"', parts[1], '"},')); 

        parts[2] = '</text><text x="10" y="40" class="base" fill="#EAACB8">';

        parts[3] = getAntiT(tokenId);
        traits[1] = string(abi.encodePacked('{"trait_type":"Anti-T","value":"', parts[3], '"},')); 

        parts[4] = '</text><text x="10" y="60" class="base" fill="#FFF">';

        parts[5] = getHead(tokenId);
        traits[2] = string(abi.encodePacked('{"trait_type":"Head","value":"', parts[5], '"},')); 

        parts[6] = '</text><text x="10" y="80" class="base" fill="#7ACBF5">';

        parts[7] = getBody(tokenId);
        traits[3] = string(abi.encodePacked('{"trait_type":"Body","value":"', parts[7], '"},')); 

        parts[8] = '</text><text x="10" y="100" class="base" fill="#EAACB8">';

        parts[9] = getLegs(tokenId);
        traits[4] = string(abi.encodePacked('{"trait_type":"Legs","value":"', parts[9], '"},')); 

        parts[10] = '</text><text x="10" y="120" class="base" fill="#FFF">';

        parts[11] = getSnack(tokenId);
        traits[5] = string(abi.encodePacked('{"trait_type":"Snack","value":"', parts[11], '"},')); 

        parts[12] = '</text><text x="10" y="140" class="base" fill="#7ACBF5">';

        parts[13] = getGame(tokenId);
        traits[6] = string(abi.encodePacked('{"trait_type":"Game","value":"', parts[13], '"},')); 

        parts[14] = '</text><text x="10" y="160" class="base" fill="#EAACB8">';

        parts[15] = getPolitics(tokenId);
        traits[7] = string(abi.encodePacked('{"trait_type":"Politics","value":"', parts[15], '"}')); 

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory traitList = string(abi.encodePacked(traits[0],traits[1],traits[2],traits[3],traits[4],traits[5],traits[6],traits[7]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Starter Kit #', toString(tokenId), '", "description": "Loot (for Trans Girls) is a collection of trans girl starter kits generated and stored on-chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use them in any way you want.", "attributes": [', traitList ,'], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintLoot(uint256 qty) public payable nonReentrant {
        require(qty <= 100, 'MAX_QTY_EXCEEDED');
        unchecked { require(mintPrice * qty <= msg.value, 'LOW_ETHER'); }
        unchecked { require(totalSupply() + qty <= maxTokens, 'MAX_REACHED'); }
        _safeMint(msg.sender, qty);
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