//   ___, __   _, ___,   ____  ____,
//  (-|_)(-|  |  (-|_)  (-(__`(-|_,
//   _|    |__|_, _| \_, ____) _|__,
//  (            (      (     (
//
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Purse is ERC721Enumerable, ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string[] private weapons = [
    "Derringer",
    "Pepper Spray",
    "Glock",
    "Sharp Keychain",
    "Scissors",
    "Metal Nail File",
    "Ballistic Dart Launcher",
    "Taser",
    "Flashlight",
    "Whistle",
    "Umbrella",
    "Hair Pin",
    "Safety Pins",
    "Ball-point Pen",
    "Tweezers"
    ];

    string[] private creams = [
    "Sunscreen",
    "Moisturizer",
    "Baby Powder",
    "Roller Perfume",
    "Wet Wipes",
    "Band-Aids",
    "Neosporin",
    "Blotting Papers",
    "Stain-eraser Pen",
    "Hand Lotion",
    "Hand Sanitizer",
    "Mints",
    "Tissues",
    "Advil",
    "Tampons",
    "Sanitary Pads",
    "Deoderant"
    ];

    string[] private makeup = [
    "Red Lipstick",
    "Pink Lipstick",
    "Lip Balm",
    "Chap Stick",
    "Lip Gloss",
    "Eyeliner",
    "Powdered Compact",
    "Mascara",
    "Foundation",
    "Blush",
    "Bronzer",
    "Contour Kit",
    "Coverup",
    "Lip Liner",
    "Brow Brush",
    "Nail Polish"
    ];

    string[] private cards = [
    "Passport",
    "Driver's License",
    "State-issued ID",
    "Gym Membership Card",
    "Warehouse Membership Card",
    "Library Card",
    "Social Security Card",
    "Birth Certificate",
    "Credit Card",
    "Debit Card",
    "Medical Card",
    "Birthday Card"
    ];

    string[] private accessories = [
    "Scarf",
    "Gloves",
    "Earrings",
    "Bracelet",
    "Watch",
    "Arm Band",
    "Fitness Tracker",
    "Smart Watch",
    "Ballet Flats",
    "Strappy Sandals",
    "Bangles",
    "Aviator Sunglasses",
    "Giant Sunglasses",
    "Drug Store Sunglasses"
    ];

    string[] private sex = [
    "Condoms",
    "Magnums",
    "Vibrator",
    "Pocket Rocket",
    "Furry Handcuffs",
    "Silk Blindfold",
    "The Rabbit",
    "Hitachi Magic Wand",
    "Paddle",
    "Lube"
    ];

    string[] private necklaces = [
    "Necklace",
    "Pendant",
    "Choker",
    "Collar",
    "Long Necklaces",
    "Gold Necklace"
    ];

    string[] private rings = [
    "Engagement Ring",
    "Wedding Ring",
    "Promise Ring",
    "Purity Ring",
    "Independence Ring"
    ];

    string[] private suffixes = [
    "of Gucci",
    "of Chanel",
    "of Balenciaga",
    "of Versace",
    "of Prada",
    "of Tom Ford",
    "of Hermes",
    "of Fendi",
    "of Burberry",
    "of Givenchy",
    "of Bulgari",
    "of Armani",
    "of Louis Vuitton",
    "of Christian Dior",
    "of Calvin Klein",
    "of Marc Jacobs"
    ];

    string[] private namePrefixes = [
    "Age-Defying", "Bedazzled", "Sparkling", "Diamond", "Couture", "Bespoke", "Custom", "Last Season's",
    "This Season's", "Flattering", "Beautiful", "Lovely", "Angelic", "Sweet", "Demure", "Fierce",
    "Basic", "Fancy", "Luxury", "Exclusive", "Special", "Cherished", "Precious",
    "Youthful", "Clean", "Scented", "Brightening", "Lightening", "Smoothing", "Clarifying",
    "Sexy", "Sultry", "Voluptuous", "Curvy", "Antique", "Vintage", "Elite", "Warming", "Comforting", "Soft", "Fluffy",
    "Furry", "Faux", "Imitation", "Dainty", "Feminine", "Glorious", "Independent"
    ];

    string[] private nameSuffixes = [
    "Pleasure",
    "Silk",
    "Glow",
    "Communication",
    "Understanding",
    "Love",
    "Share",
    "Comfort",
    "Warmth",
    "Safety"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }

    function getCream(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CREAM", creams);
    }

    function getMakeup(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MAKEUP", makeup);
    }

    function getCards(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CARDS", cards);
    }

    function getAccessories(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ACCESSORIES", accessories);
    }

    function getSex(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SEX", sex);
    }

    function getNeck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NECK", necklaces);
    }

    function getRing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RING", rings);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 17) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if(greatness < 19) {
                output = string(abi.encodePacked(name[0], ' ', output));
            } else if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: cursive; font-size: 14px; }</style><rect width="100%" height="100%" fill="#F69AB1" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getCream(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getMakeup(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getCards(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getAccessories(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getSex(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Purse #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function mint() public {
        _tokenIds.increment();
        claim(_tokenIds.current());
    }

    function claim(uint256 tokenId) internal nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8009, "Token ID invalid");
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

    constructor() ERC721("Purse", "PURSE") Ownable() {}
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
