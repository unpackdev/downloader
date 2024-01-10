// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.4;


import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract Loot_tacobell is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint = 5000;
  uint256 public immutable amountForDevs = 10000000000000;
  uint256 public immutable amountForAuctionAndDev = 1000000000;
  uint256 public immutable collectionSize = 5000000;
  uint256 public immutable maxBatchSize = 5000;

  struct SaleConfig {
    uint32 auctionSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
    uint32 publicSaleKey;
  }
    function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

function publicSaleMint(uint256 quantity, uint256 )
    external
    payable
  {
    _safeMint(msg.sender, quantity);
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;
  constructor() ERC721A("TACOLOOT", "TACO") {}

    // 18
    string[] private sauce = [
        "Avocado Ranch Sauce",
        "Border Sauce - Diablo",
        "Border Sauce - Fire",
        "Border Sauce - Hot",
        "Border Sauce - Mild",
        "Breakfast Salsa",
        "Creamy Chipotle Sauce",
        "Creamy Jalapeno Sauce",
        "Green Sauce",
        "Nacho Cheese Sauce",
        "Red Sauce",
        "Spicy Ranch Sauce"
    ];

    // 15
    string[] private topping = [
        "Bacon",
        "Black Beans",
        "Cheddar Cheese",
        "Guacamole",
        "Iceberg Lettuce",
        "Jalapenos",
        "Onions",
        "Pinto Beans",
        "Red Strips",
        "Reduced-Fat Sour Cream",
        "Sausage Crumbles",
        "Three Cheese Blend",
        "Tomatoes"
    ];

    // 15 
    string[] private protein = [
        "Chili",
        "Crispy Tortilla Chicken",
        "Eggs",
        "Grilled Chicken",
        "Hash Brown",
        "Potato Bites",
        "Refried Beans",
        "Seasoned Beef",
        "Seasoned Rice"
    ];
    // 15
    string[] private wrap = [
        "Chalupa Shell",
        "Doritos Locos Taco Nacho Cheese Shell",
        "Flour Tortilla",
        "Gordita Flatbread",
        "Nacho Chips",
        "Puffy Flatbread",
        "Taco Shell",
        "Tostada Shell",
        "USDA Select Marinated Grilled Steak"
    ];

    string[] private drink = [
        "Barqs Caffeine Free Root Beer",
        "Beach Berry Freeze",
        "Blue Raspberry Freeze",
        "Brisk Mango Iced Tea",
        "Brisk Unsweetened No Lemon Iced Tea",
        "Calebs Kola",
        "Coca Cola",
        "Diet Coke",
        "Diet Dr. pepper",
        "Diet Mtn Dew",
        "Diet Pepsi",
        "Dr. Pepper",
        "Fanta Orange",
        "G2 - Fruit Punch",
        "Ginger Mule Freeze",
        "IZZE Sparkling Clementine",
        "Lowfat Milk",
        "Margarita Freeze",
        "Minute Maid Lemonade",
        "Mtn Dew",
        "Mtn Dew Baja Blast Freeze",
        "Mtn Dew Baja Blast Zero Sugar",
        "Mtn Dew Baja Blast",
        "Mtn Dew Kickstart Orange Citrus",
        "Mug Root Beer",
        "Nestle Coffee-Mate Sweetened Original Creamer",
        "Party Punch Freeze",
        "Pepsi",
        "Pepsi Wild Cherry",
        "Pepsi Zero Sugar",
        "Rainforest Coffee",
        "Ready-to-Drink Margarita Wine Cocktail - Classic",
        "Ready-to-Drink Margarita Wine Cocktail - Strawberry",
        "Sierra Mist",
        "Sprite",
        "Stubborn Soda - Black Cherry with Tarragon",
        "Stubborn Soda - Classic Root Beer",
        "Tropicana Orange Juice",
        "Tropicana Pink Lemonade",
        "Wild Strawberry Freeze"
    ];
    
    // 15
    string[] private suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Fury",
        "of Vitriol",
        "of the Fox",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];
    
    // string[] private namePrefixes = [
    //     "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
    //     "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
    //     "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", 
    //     "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
    //     "Kraken", "Loath", "Maelstrom", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
    //     "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
    //     "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Wrath",
    //     "Light's", "Shimmering"  
    // ];
    
    // string[] private nameSuffixes = [
    //     "Bane",
    //     "Root",
    //     "Bite",
    //     "Song",
    //     "Roar",
    //     "Grasp",
    //     "Instrument",
    //     "Glow",
    //     "Bender",
    //     "Shadow",
    //     "Whisper",
    //     "Shout",
    //     "Growl",
    //     "Tear",
    //     "Peak",
    //     "Form",
    //     "Sun",
    //     "Moon"
    // ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getSauce1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SAUCE_1", sauce);
    }

    function getSauce2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SAUCE_2", sauce);
    }
    
    function getTopping1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TOPPING_1", topping);
    }

    function getTopping2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TOPPING_2", topping);
    }
    
    function getProtein1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "PROTEIN_1", protein);
    }

    function getProtein2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "PROTEIN_2", protein);
    }

    function getWrap(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WRAP", wrap);
    }

    function getDrink(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DRINK", drink);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        // uint256 greatness = rand % 21;
        // output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        output = string(abi.encodePacked(output));
        // if (greatness >= 19) {
        //     string[2] memory name;
        //     name[0] = namePrefixes[rand % namePrefixes.length];
        //     name[1] = nameSuffixes[rand % nameSuffixes.length];
        //     if (greatness == 19) {
        //         output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
        //     } else {
        //         output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
        //     }
        // }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getSauce1(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getSauce2(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getTopping1(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getTopping2(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getProtein1(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getProtein2(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getWrap(tokenId);(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getDrink(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
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

