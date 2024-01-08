// SPDX-License-Identifier: MIT
// Heavily inspired by the loot contract, and written for the loot ecosystem.

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.0;

contract NPCs is ERC721Enumerable, Ownable, ReentrancyGuard {
    LootInterface lootContract = LootInterface(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
    constructor() ERC721("NPCs (for Adventures)", "LootNPCs") {}

    string[] private firstName = [
        "Dan",
        "Arthur",
        "Diana",
        "Dane",
        "Falledrick",
        "Kulo",
        "Ovid",
        "Eledryl",
        "Clappa",
        "Garrett",
        "Gorm",
        "Thultha",
        "Leeroy",
        "Kip",
        "Patric",
        "Dodd",
        "Grax",
        "Agaro",
        "Glint",
        "Worthy",
        "Yox",
        "Dlrow",
        "Sarai",
        "Gwend",
        "Barthinda",
        "Elon",
        "Ninmon",
        "Greven",
        "Orn",
        "Ink",
        "Trurth",
        "Naarkisk",
        "Frank",
        "Thultha",
        "Jay",
        "Matilda",
        "Stanley",
        "Exokur",
        "Limble",
        "Onomono",
        "Perrik", 
        "Kastevi",
        "Mered",
        "Cacac",
        "Ulret",
        "Bobin",
        "Sadon",
        "Terawin",
        "Rowan",
        "Ramgnar",
        "Ashalis",
        "Fundrul",
        "Brod",
        "Phadri",
        "Rose"
    ];

    string[] private lastName = [
        "Copperhearth",
        "Rickenforth",
        "Higgenbottom",
        "Cobbledick",
        "Cornfoot",
        "Hogwood",
        "Nutters",
        "Onions",
        "Rattlebagg",
        "Bonanno",
        "Zaytoun",
        "Baba",
        "Jenkins",
        "Sajak",
        "Gunderson",
        "Rockworm",
        "Hooperbag",
        "Sicklederry",
        "Pinkerton",
        "Ferdea",
        "Tfarcraw",
        "Oakenthorn",
        "Smallwood",
        "Bomblepip",
        "Ragnarson",
        "The Unbroken",
        "The Great",
        "The Weak",
        "The Warrior",
        "The Unholy",
        "The Undying",
        "The Weak",
        "The Fair",
        "The Just",
        "The Old",
        "The Young",
        "The Wise",
        "The Terrible",
        "Johnson",
        "Ironeye",
        "Stack",
        "Avarixas",
        "Lester",
        "Gadmonton",
        "Essterlad",
        "Fifthwind"
    ];
    
    string[] private species = [
        "Human",
        "Halfling",
        "Elf",
        "Dwarf",
        "Orc",
        "Goblin",
        "Golem",
        "Centaur",
        "Fairy",
        "Sprite",
        "Gremlin",
        "Knight",
        "King",
        "Giant",
        "Warlock",
        "Gnome",
        "Oracle",
        "Mermaid",
        "Ent",
        "Minotaur",
        "Weasel",
        "Munchkin",
        "Beast",
        "Ghost",
        "Genie",
        "Angel",
        "Demon",
        "Demi-God",
        "Ape",
        "Bear"
    ];
    
    string[] private speciesModifier = [
        "Puny",
        "Wood",
        "Undead",
        "Dark",
        "Evil",
        "Forest",
        "Mountain",
        "Sea",
        "City",
        "Town",
        "Desert",
        "Unintelligible",
        "Water",
        "High",
        "Low",
        "Very High",
        "Quite Large",
        "Forsaken",
        "Fire",
        "Blessed",
        "Enlightened",
        "Ice",
        "Blessed",
        "Zombie",
        "Invisible",
        "Monstrous",
        "Wise",
        "Godlike"
    ];
    
    string[] private occupation = [
        "Guard",
        "Merchant",
        "Innkeeper",
        "Thief",
        "Bard",
        "Townie",
        "Tailor",
        "Blacksmith",
        "Cook",
        "Fisherman",
        "Sailor",
        "Mercenary",
        "Scholar",
        "Philosopher",
        "Cobbler",
        "Rancher",
        "Peddlar",
        "Barkeep",
        "Wench",
        "Traveler",
        "Court Fool",
        "Street Meat Peddler",
        "Witch-In-Training",
        "Keeper of the Keys",
        "Ratter",
        "High Priestess",
        "Goon",
        "Pyromancer",
        "Time Wizard",
        "Necromancer",
        "Librarian",
        "Demon Slayer",
        "Death Knight",
        "Water Dancer",
        "Low Priest",
        "Low Priestess",
        "Undertaker",
        "Village Idiot"
        "Ne'er Do Well",
        "Scallywag",
        "Know-It-All",
        "Kid Detective",
        "Adult Detective",
        "Kidnapper",
        "Sex Criminal",
        "Lady of Negotiable Affection",
        "Falconer",
        "Brothel Owner",
        "Leper",
        "Executioner",
        "Hangman",
        "Ealderman",
        "Oracle",
        "Seer",
        "Adventurer",
        "Cult Leader",
        "Soldier of Fortune",
        "Cultist",
        "Shepherd",
        "Stablehand",
        "Farmer",
        "Eunuch",
        "Spy"
    ];
    
    string[] private occupationModifier = [
        "Unemployed",
        "Disgruntled",
        "Talkative",
        "Exhausted",
        "Successful",
        "Overpaid",
        "Drunken",
        "Crippled",
        "Loud",
        "Struggling",
        "Bastard",
        "Lowly",
        "Just",
        "Widowed",
        "Lusty",
        "Condescending",
        "Overachieving",
        "Feckless",
        "Overeducated",
        "Fearless",
        "Conniving",
        "Antiquated",
        "Diabolical",
        "Nude",
        "Stinky",
        "Put-Together",
        "Well-Endowed",
        "Ambitious",
        "Annoying",
        "Clumsy",
        "Competent",
        "Famous",
        "Secretly Magical",
        "Ineffable",
        "Incompetent",
        "Sexy",
        "Amateur"
    ];
    
    string[] private disposition = [
        "Happy",
        "Scared",
        "Amused",
        "Befuddled",
        "Depressed",
        "Ecstatic",
        "Bored",
        "Excited",
        "Unaware",
        "Stoned",
        "Bubbly",
        "Eager",
        "Loathsome",
        "Disgruntled",
        "Nervous",
        "Overconfident",
        "Neurotic",
        "Fearless",
        "Bold",
        "Inspired",
        "Eager",
        "Listless",
        "Apathetic",
        "Arrogant",
        "Unaware",
        "Courteous",
        "Peckish",
        "Fulsome",
        "Bumbling",
        "Recalcitrant",
        "Unwavering",
        "Stalwart",
        "Bombastic",
        "Pious",
        "Demure",
        "Deceitful",
        "Snide",
        "Precocious"
    ];
    
    string[] private dispositionModifier = [
        "Annoyingly",
        "Flamboyantly",
        "Despairingly",
        "Drunkenly",
        "Begrudgingly",
        "Sickeningly",
        "Jokingly",
        "Bastardly",
        "Connivingly",
        "Unabashedly",
        "Desperately", 
        "Eagerly",
        "Cleverly",
        "Violently",
        "Beligerently",
        "Cautiously",
        "Anxiously",
        "Merrily",
        "Terribly",
        "Exceedingly",
        "Unnervingly",
        "Deservedly",
        "Undoubtedly",
        "Ridiculously",
        "Secretly"
    ];
    
    string[] private clothing = [
        "Tunic",
        "Cloak",
        "Mail",
        "Armor",
        "Gown",
        "Doublet",
        "Jerkin",
        "Overgown",
        "Dress",
        "Cuirass",
        "Frock",
        "Furs",
        "Cassock",
        "Jester Outfit",
        "Breeches",
        "Petticoat", 
        "Pantaloons",
        "Smock",
        "Robes",
        "Rags",
        "Gown",
        "Vest",
        "Skin",
        "Scales",
        "Shirt",
        "Bones"
    ];
    
    string[] private clothingModifier = [
        "Crimson",
        "Violet",
        "Mauve",
        "Alabaster",
        "Pewter",
        "Hazelnut",
        "Canary",
        "Tangerine",
        "Flamingo",
        "Indigo",
        "Cerulean",
        "Chartreuse",
        "Ill-fitting",
        "Drooping",
        "Tattered",
        "Glistening",
        "Colorful",
        "Leather",
        "Mithril",
        "Old",
        "Textured",
        "Embroidered",
        "Leather",
        "Tattered",
        "Ruined",
        "Glowing"
    ];
    
    string[] private accessory = [
        "Boots",
        "Gauntlets",
        "Gloves",
        "Mask",
        "Satchel",
        "Eyepatch",
        "Belt",
        "Wineskin",
        "Necklace",
        "Horn",
        "Bracelet",
        "Coin Purse",
        "Ring",
        "Pitchfork",
        "Banana",
        "Lobster",
        "Fish",
        "Potion",
        "Dagger",
        "Longsword",
        "Bow",
        "Key",
        "Scroll",
        "Axe",
        "Spear",
        "Bread",
        "Coins",
        "Hat",
        "Wand",
        "Staff",
        "Map",
        "Rug",
        "Chicken",
        "Backpack",
        "Ledger",
        "Hammer"
    ];
    
    string[] private accessoryModifier = [
        "Shiny",
        "Worn",
        "Sparkling",
        "Black",
        "Bloody",
        "Oversized",
        "Nondescript",
        "Unflattering",
        "Frayed",
        "Dusty",
        "Gray",
        "Pointy",
        "Intimidating",
        "Tiny",
        "Golden",
        "Cheap",
        "Inexplicable",
        "Magic",
        "Ancient",
        "Burnt",
        "Cursed",
        "Legendary",
        "Stolen",
        "Divine",
        "Forgettable",
        "Slippery",
        "Stinky",
        "Ugly",
        "Diamond",
        "Common"
    ];
    
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getName(uint256 tokenId) public view returns (string memory) {
        return combine(tokenId, "NAME", firstName, lastName, true);
    }
    
    function getSpecies(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SPECIES", species, speciesModifier);
    }
    
    function getOccupation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "JOB", occupation, occupationModifier);
    }
    
    function getDisposition(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DISPO", disposition, dispositionModifier);
    }
    
    function getClothing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLOTH", clothing, clothingModifier);
    }
    
    function getAccessory(uint256 tokenId) public view returns (string memory) {
        return combine(tokenId, "ACCESS", accessory, accessoryModifier, false);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray, string[] memory modifierArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 describe = rand % 10; 
        if (describe > 5) { // ~60% Chance of Modifier
            return string(abi.encodePacked(output));
        }
        else {
            uint256 rand2 = random(string(abi.encodePacked(toString(tokenId), keyPrefix)));
            string memory outputMod = modifierArray[rand2 % modifierArray.length];
            return string(abi.encodePacked(outputMod, " ", output));
        }
    }

    function combine(uint256 tokenId, string memory keyPrefix, string[] memory firstArray, string[] memory lastArray, bool inOrder) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = firstArray[rand % firstArray.length];
        uint256 rand2 = random(string(abi.encodePacked(toString(tokenId), keyPrefix)));
        string memory outputLast = lastArray[rand2 % lastArray.length];
        
        if (inOrder) {
            return string(abi.encodePacked(output, " ", outputLast));
        }
        else {
            return string(abi.encodePacked(outputLast, " ", output));
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        
        string[13] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getName(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getSpecies(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getOccupation(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getDisposition(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getClothing(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getAccessory(tokenId);

        parts[12] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "NPC #', toString(tokenId), '", "description": "NPCs are randomized characters generated and stored on chain. Everything not specifically declared is open for interpretation. Feel free to include NPCs in your adventures!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    // Allow looters to claim their corresponding token IDs.
    function looterClaim(uint256 tokenId) public nonReentrant {
        require(tokenId < 8000, "Only the first 8k are reserved for loot holders.");
        require(lootContract.ownerOf(tokenId) == msg.sender, "Not the owner of this loot");
        require(!_exists(tokenId), "This token has already been minted");

        _safeMint(msg.sender, tokenId);
    }
    // Allow the public to mint 4k more.
    function publicClaim(uint256 tokenId) public payable nonReentrant {
        require(tokenId < 12000 && tokenId >= 8000, "There's only 12k total NPCs and the first 8k are reserved for loot holders.");
        require(!_exists(tokenId), "This token has already been minted");
        require(msg.value >= 1*10**16, "Public claiming costs .01 ETH.");
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

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
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