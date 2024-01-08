// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./RevSharable.sol";

contract WeedLoot is ERC721Enumerable, ReentrancyGuard, Ownable, RevSharable {

    uint256 public _currentTokenId = 1;
    uint256 public costToMint = 10000000000000000;

    string[] private weed1 = [
        "Half Eighth", 
        "Nickel Bag", 
        "Dime Bag", 
        "Quarter", 
        "Mids", 
        "Regs"
        "Beasters", 
        "BC's", 
        "Bong Water", 
        "Shatter", 
        "Hash", 
        "Trichomes", 
        "Oil", 
        "Wax", 
        "Spliff", 
        "Ghani", 
        "Bag of Oregano"
    ];

    string[] private weed2 = [
        "Kush", 
        "Purple kush", 
        "White widow", 
        "Seeds", 
        "Granddaddy Purp"
        "Maui Wowie", 
        "Blue Dream", 
        "Northern Lights", 
        "Pineapple Express", 
        "Stems", 
        "Green Dragon", 
        "CBD", 
        "Bag of Actual Grass", 
        "Secret Resin", 
        "Mids Shake", 
        "Regs Shake"
    ];

    string[] private device = [
        "Steam Roller",
        "Vape",
        "Grav",
        "Bong",
        "Bubbler",
        "Waterfall",
        "Knife Hit",
        "Corncob Pipe",
        "Dryer Sheet",
        "White Owl",
        "Backwood",
        "Joint",
        "Oney",
        "Little Hitter",
        "Dugout",
        "Hollow Apple",
        "Gandolf Pipe",
        "Dutchmaster",
        "Greenleaf",
        "Highlighter Pipe",
        "Shotgun",
        "Chillum",
        "Dab",
        "Resin",
        "Cart",
        "Hot Box",
        "Shotgun",
        "Volcano Vape",
        "Swisher Sweet",
        "Percolator",
        "Acrylic Bong",
        "10 Foot Bong",
        "Gasmask Bong",
        "Wizard Pipe",
        "Rusty Can",
        "Socket",
        "10 Foot Acrylic Bong",
        "Cross Joint"
    ];

    string[] private snack1 = [
        "3D Doritos",
        "Cheeto Dust",
        "Gummy Worms",
        "Snickers",
        "Stale Club Crackers",
        "Craft Singles",
        "Cheezits",
        "Soggy Taco",
        "Chocco Taco",
        "Stale Taco",
        "Quesadilla",
        "Kit-Kat",
        "Ice Cream",
        "Pringles",
        "Cheese Dip",
        "Funyuns",
        "Cup Ramen",
        "Pizza Rolls",
        "Lunchables",
        "Cosmic Brownie"
    ];

    string[] private snack2 = [
        "Sour Starburst",
        "EZ Mac",
        "Pizza",
        "Burrito",
        "Dunkaroos",
        "Lunchable",
        "Flaming Hot Cheetos",
        "Sour Straws",
        "Double Stuffed Oreos",
        "Oreos",
        "Hot Pocket",
        "Slim Jim",
        "Sour Gummy Worms",
        "Taquis",
        "White Cheddar Popcorn",
        "Honey Bun",
        "Nachos",
        "Pop Rocks",
        "Nerds Rope"
    ];

    string[] private drink = [
        "Vanilla Coke",
        "Baja Blast",
        "Bubble Water",
        "Chocolate Milk",
        "Milkshake",
        "Faygo",
        "Water",
        "Slurpee",
        "Arizona Tea",
        "Milk",
        "Lipton Ice Tea",
        "Coke",
        "Sprite",
        "Lemonade",
        "Pink Lemonade",
        "Gatorade Glacier Freeze",
        "Redbull",
        "Slush Puppy Blue Rasperry",
        "Gatorade Fruit Punch",
        "Gatorade Lemon-Lime",
        "Gatorade Orange",
        "Gatorade Mango Extremo",
        "Slush Puppy Cherry",
        "Slush Puppy Grape",
        "Dr Pepper",
        "Mr Pibb",
        "Root Beer",
        "7 Up",
        "Surge",
        "Sierra Mist",
        "Cream Soda ",
        "Arnold Palmer",
        "Fanta",
        "Monster"
    ];

    string[] private accessory1 = [
        "Sploof",
        "Llighter",
        "Dryer Sheet",
        "Grinder",
        "Ozium",
        "Incense",
        "Tie Dye Hoodie",
        "Skateboard",
        "Hacky Sack",
        "Frisbee",
        "Filter",
        "Febreze",
        "Cool S",
        "Longboard",
        "Visine",
        "Rotos",
        "Rolling tray"
    ];

    string[] private accessory2 = [
        "Scale",
        "Ash tray",
        "Snuggy",
        "Birkenstocks",
        "Hoodie",
        "Roach Clip",
        "311 CD",
        "Weed Butter",
        "Blacklight Poster",
        "Wall Tapestry",
        "Couch",
        "Fitted Hat",
        "Tie Dye Shirt",
        "Rip Stick",
        "Huffy Bike",
        "Dice",
        "Crocs",
        "Vibrams",
        "Osiris D3s",
        "iPaths"
    ];
    
    string[] private suffixes = [
        "of Power",
        "of Rage",
        "of Exhaustion",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Paranioa",
        "of Old",
        "of Luck",
        "of Rage",
        "of Fury",
        "of Boredom",
        "of Knowledge",
        "of Regret",
        "of Reflection",
        "of the 3rd Dimension",
        "of the 420th Dimension"
    ];

    string[] private prefixes = [
        "Gas Station",
        "Sketchy",
        "Holy",
        "Elder",
        "Divine",
        "Older Brother's",
        "Older Sister's",
        "Holographic",
        "Moldy",
        "Mystic",
        "Mighty",
        "Fossilized",
        "Ornate",
        "Spectacular",
        "Vengeful",
        "Weak",
        "Moderate"
    ];

    function getWeed(uint256 tokenId, string memory salt) public view returns (string memory) {
        return pluck(tokenId, "WEED", salt, weed2);
    }

    function getDevice(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DEV", "", device);
    }

    function getSnack(uint256 tokenId, string memory salt) public view returns (string memory) {
        return pluck(tokenId, "SNACK", salt, snack2);
    }

    function getDrink(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "Drink", "", drink);
    }

    function getAccessory(uint256 tokenId, string memory salt) public view returns (string memory) {
        return pluck(tokenId, "ACC", salt, accessory1);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string memory salt, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = Helper.random(string(abi.encodePacked(keyPrefix, salt, Helper.toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string memory prefix;
            prefix = prefixes[rand % prefixes.length];
            
            if (greatness == 19) {
                output = string(abi.encodePacked(prefix, ' ', output));
            } else {
                output = string(abi.encodePacked(prefix, ' ', output, " +420"));
            }
        }
        return output;
    }

    function getSvg(uint256 tokenId) private view returns (string memory) {
        string[17] memory parts;

        parts[0] = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.b { fill: #64A925; font-family: serif; font-size: 14px; }</style><rect width='100%' height='100%' fill='#E0FBD2' /><text x='10' y='20' class='b'>";
        parts[1] = getWeed(tokenId, "1");

        parts[2] = "</text><text x='10' y='40' class='b'>";

        parts[3] = getWeed(tokenId, "2");

        parts[4] = "</text><text x='10' y='60' class='b'>";

        parts[5] = getDevice(tokenId);

        parts[6] = "</text><text x='10' y='80' class='b'>";

        parts[7] = getSnack(tokenId, "1");

        parts[8] = "</text><text x='10' y='100' class='b'>";

        parts[9] = getSnack(tokenId, "2");

        parts[10] = "</text><text x='10' y='120' class='b'>";

        parts[11] = getDrink(tokenId);

        parts[12] = "</text><text x='10' y='140' class='b'>";

        parts[13] = getAccessory(tokenId, "1");

        parts[14] = "</text><text x='10' y='160' class='b'>";

        parts[15] = getAccessory(tokenId, "2");

        parts[16] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        return output;
    }

    function getMeta(uint256 tokenId) private view returns (string memory) {
        string[17] memory parts;

        parts[0] = ', "attributes": [{"trait_type": "weed", "value": "';
        parts[1] = getWeed(tokenId, "1");
        parts[2] = '"},{"trait_type": "weed", "value": "';
        parts[3] = getWeed(tokenId, "2");
        parts[4] = '"},{"trait_type": "device", "value": "';
        parts[5] = getDevice(tokenId);
        parts[6] = '"},{"trait_type": "snack", "value": "';
        parts[7] = getSnack(tokenId, "1");
        parts[8] = '"},{"trait_type": "snack", "value": "';
        parts[9] = getSnack(tokenId, "2");
        parts[10] = '"},{"trait_type": "drink", "value": "';
        parts[11] = getDrink(tokenId);
        parts[12] = '"},{"trait_type": "accessory", "value": "';
        parts[13] = getAccessory(tokenId, "1");
        parts[14] = '"},{"trait_type": "accessory", "value": "';
        parts[15] = getAccessory(tokenId, "2");
        parts[16] = '"}]';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        return output; 
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory output = getSvg(tokenId);
        string memory meta = getMeta(tokenId);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', Helper.toString(tokenId), '", "description": "Weed Loot is randomized adventurer gear randomly generated, stored, and smoked on chain. Stats, Images, and other functionality are intentionally omitted for others to interpret. Feel free to use Weed Loot in any way you want.", "image_data": "', bytes(output), '"', bytes(meta),'}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function claim() payable public nonReentrant {
        require(_currentTokenId < 4201, "Token invalid");
        require(msg.value >= costToMint, 'less than costToMint');
        _safeMint(_msgSender(), _currentTokenId);
        _incrementTokenId();
    }

    function ownerClaim() public nonReentrant onlyOwner {
        require(_currentTokenId < 4201, "Token invalid");
        _safeMint(owner(), _currentTokenId);
        _incrementTokenId();
    }

    function setCostToMint(uint256 _costToMint) public onlyOwner {
        costToMint = _costToMint;
    }
      
    constructor() ERC721("Weed Loot (For Adventurers)", "WEEDLOOT") Ownable() {}
}

library Helper {
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

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}

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