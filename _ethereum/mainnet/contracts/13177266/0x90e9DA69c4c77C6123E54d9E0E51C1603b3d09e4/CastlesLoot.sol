// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/*

  _______________________________________
 /                                       \
/   _   _   _                 _   _   _   \
|  | |_| |_| |   _   _   _   | |_| |_| |  |
|   \   _   /   | |_| |_| |   \   _   /   |
|    | | | |     \       /     | | | |    |
|    | |_| |______|     |______| |_| |    |
|    |              ___              |    |
|    |  _    _    (     )    _    _  |    |
|    | | |  |_|  (       )  |_|  | | |    |
|    | |_|       |       |       |_| |    |
|   /            |_______|            \   |
|  |___________________________________|  |
\ CASTLESDAO presents: Castles Gen One    /
 \_______________________________________/

*/

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CastlesLoot is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public lootersPrice = 10000000000000000; // 0.01 ETH
    uint256 public price = 100000000000000000; //0.1 ETH
    bool public lockedForLooters = true;

    // This will be locked for some time, to allow looters to get their castle first
    function flipLockedForLooters() public onlyOwner {
        lockedForLooters = !lockedForLooters;
    }

    function setLootersPrice(uint256 newPrice) public onlyOwner {
        lootersPrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function ownerWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //Loot Contract
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface public lootContract = LootInterface(lootAddress);

    string[] private warriors = [       
        "Champion",
        "Dragon",
        "Frog",
        "Ghost",
        "Golem",
        "King",
        "Witch",
        "Punk Alien",
        "Punk Ape",
        "Skeleton",
        "Wizard",
        "Barbarian",
        "Priest"
    ];

    string[] private skillTypes = [
        "damage",
        "speed",
        "gold generation",
        "defense",
        "agility",
        "intelligence",
        "charisma",
        "ability power",
        "fear"
    ];

    string[] private protectedNames = [
        "Defended",
        "Protected",
        "Guarded",
        "Shielded",
        "Safeguarded",
        "Fortified",
        "Secured",
        "Hardened",
        "Walled"
    ];

    string[] private races = [
        "Goblin",
        "Human",
        "Dwarf",
        "Elf",
        "Undead",
        "Orc",
        "Imp",
        "Ape",
        "Faerie",
        "Troll",
        "Angel",
        "Djinn",
        "Shade",
        "Shapeshifter",
        "Spirit",
        "Golem",
        "Halfling",
        "Leoning",
        "Triton",
        "Demon",
        "Centaur",
        "Loxodon",
        "Minotaur",
        "Vedalken",
        "Merfolk",
        "Dark-Elf",
        "Balrog",
        "Ent"
    ];

    string[] private backgrounds = [
        "Beggar",
        "Adventurer",
        "Scholar",
        "Gambler",
        "Wizard",
        "Alchemist",
        "Soldier",
        "Merchant",
        "Warrior",
        "Noble",
        "Healer",
        "Cleric",
        "Acolyte",
        "Lord",
        "Charlatan",
        "Crafter",
        "Criminal",
        "Traveler",
        "Gambler",
        "Gladiator",
        "Artisan",
        "Hermit",
        "Marine",
        "Sailor",
        "Assassin",
        "King",
        "Queen"
    ];

    string[] private castleTypes = [
        "Fortress",
        "Tower",
        "Castle",
        "Prison",
        "Guard",
        "Defense",
        "Stronghold",
        "Citadel",
        "Palace",
        "Lair",
        "House",
        "Barracks",
        "Dome",
        "Fort",
        "Alcazar",
        "Acropolis",
        "Garrison",
        "Chateau",
        "Catacombs"
    ];

    string[] private castleTitles = [
        "of Doom",
        "of Sweetness",
        "of Treachery",
        "of Happiness",
        "of Terror",
        "of Ethereum",
        "of the brave",
        "of Gold",
        "of Silver",
        "of Diamonds",
        "of the Divine",
        "of Fire",
        "of Pleasure",
        "of Death",
        "of Life",
        "of Quantum Forces",
        "of Despair",
        "of Magic",
        "of the DAO",
        "of the Seven Lords",
        "of the Emperor",
        "of Blood",
        "of Evil",
        "of Darkness",
        "of Light",
        "of Insanity",
        "of Horror",
        "of Skulls",
        "of Sorrow"
    ];

    

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
   
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Returns a random item from the list, always the same for the same token ID
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));

        return sourceArray[rand % sourceArray.length];
    }



    // 0 - 99 + 10 for warrior
    function getDefense(uint256 tokenId) public view returns (uint256) {
        // Random defense + if has warrior + 15
        uint256 rand = random(string(abi.encodePacked("DEFENSE", toString(tokenId))));
        uint256 numberDefense = rand % 99;

        string memory warrior = getWarrior(tokenId);

        // If not has warrior, return defense
        if (compareStrings(warrior, "none")) {
            return numberDefense;
        }

        // Has warrior, return defense + 15
        return numberDefense  + 15;
    }

    // 0 - 25
    function getGoldGeneration(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: Non minted NFT");
        uint256 rand = random(string(abi.encodePacked("GOLD_GENERATION", toString(tokenId))));
        return rand % 25;
    }

    // 1-255
    function getCapacity(uint256 tokenId) public view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("CAPACITY", toString(tokenId))));
        return (rand % 254) + 1;
    }

    // 1 - 25
    function getSkillAmount(uint256 tokenId) public view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("SKILL_AMOUNT", toString(tokenId))));
        return (rand % 25) + 1;
    }

    // 1-10
    function getRarityNumber(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: Non minted NFT");
        uint256 goldGeneration = getGoldGeneration(tokenId);
        uint256 defense = getDefense(tokenId);
        uint256 capacity = getDefense(tokenId);
        uint256 skillAmount = getSkillAmount(tokenId);

        uint256 rarity = 0;

        // Good gold generation
        if (goldGeneration > 10) {
            rarity +=1;
            if (goldGeneration >= 15) {
                rarity+=1;
            }
        }
        // if defense 
        if(defense > 70) {
            rarity +=1;
            if (defense > 80) {
                rarity +=1;

                if (defense > 90) {
                    rarity+=1;
                }
            }
        }

        // has capacity
        if (capacity > 150) {
            rarity +=1;

            if (capacity > 220) {
                rarity+=1;
            }
        }

        // has skillz
        if (skillAmount > 10) {
            rarity +=1;

            if (skillAmount >= 15) {
                rarity+=1;
            }
            if (skillAmount >= 20) {
                rarity+=1;
            }
        }

        return rarity;
    }

    function getRarity(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Non minted NFT");
        uint256 rarity = getRarityNumber(tokenId);

        if (rarity > 6) {
            return "Divine";
        }

        if (rarity > 4) {
            return "Mythic";
        }

        if (rarity > 2) {
            return "Rare";
        }

        return "Common";
    }

    function getSkillType(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SKILL", skillTypes);
    }

    function getCastleType(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CASTLE_TYPE", castleTypes);
    }

    // Visible 

    function getWarrior(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("WARRIOR_PROBABILITY", toString(tokenId))));
        if ((rand % 99) < 30 ) {
            return pluck(tokenId, "WARRIOR", warriors);
        } 
        return "none";
    }

    function getWarriorName(uint256 tokenId) public view returns (string memory) {
        string memory warrior = getWarrior(tokenId);
        
        if (compareStrings(warrior, "none")) {
            return "none";
        }

        return string(abi.encodePacked(pluck(tokenId, "WARRIOR_BACKGROUND", backgrounds), " ", warrior));
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        string memory warrior = getWarrior(tokenId);
        string memory castleType = getCastleType(tokenId);
       
        // If does not have warrior
        if (compareStrings(warrior, "none")) {
            // Calculate the castle title
            uint256 rand = random(string(abi.encodePacked("CASTLE_TITLE_PROBABILITY", toString(tokenId))));
            uint256 withOwnerName = rand % 99;
            string memory castleTitle = pluck(tokenId, "CASTLE_TITLE", castleTitles);

           
            if (withOwnerName < 75 ) {
                string memory race = pluck(tokenId, "CASTLE_TITLE_RACE", races);
                string memory background = pluck(tokenId, "CASTLE_TITLE_BACKGROUND", backgrounds);
                if (withOwnerName < 25) {
                    castleTitle = string(abi.encodePacked("of the ", background, " ", race));
                } else if (withOwnerName < 50) {
                    castleTitle = string(abi.encodePacked("of the ", background, "s"));
                }else{
                    castleTitle = string(abi.encodePacked("of the ", race, "s"));
                }
                
            } 

            return string(abi.encodePacked(castleType, " ", castleTitle));
        }

        string memory warriorName = getWarriorName(tokenId);

        return string(abi.encodePacked(pluck(tokenId, "PROTECTED_NAME", protectedNames), " ", castleType, " of the ", warriorName));
    }

    string[] private traitCategories = [
        "Name",
        "CastleType",
        "Defense",
        "SkillType",
        "SkillAmount",
        "GoldGeneration",
        "WarriorName",
        "Warrior",
        "Capacity",
        "RarityNumber",
        "Rarity"
    ];
    
    function traitsOf(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Non minted NFT");
        string[11] memory traitValues = [
            getName(tokenId),
            getCastleType(tokenId),
            toString(getDefense(tokenId)),
            getSkillType(tokenId),
            toString(getSkillAmount(tokenId)),
            toString(getGoldGeneration(tokenId)),
            getWarriorName(tokenId),
            getWarrior(tokenId),
            toString(getCapacity(tokenId)),
            toString(getRarityNumber(tokenId)),
            getRarity(tokenId)
        ];

        string memory resultString = "[";
        for (uint8 j = 0; j < traitCategories.length; j++) {
        if (j > 0) {
            resultString = strConcat(resultString, ", ");
        }
        resultString = strConcat(resultString, '{"trait_type": "');
        resultString = strConcat(resultString, traitCategories[j]);
        resultString = strConcat(resultString, '", "value": "');
        resultString = strConcat(resultString, traitValues[j]);
        resultString = strConcat(resultString, '"}');
        }
        return strConcat(resultString, "]");
    }


    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    string private baseURI = "https://castles-nft.vercel.app/api/castle/";

    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        if (lockedForLooters) {
            require(tokenId > 8000 && tokenId <= 9900, "Token ID invalid");
        } else {
            require(tokenId > 0 && tokenId <= 9900, "Token ID invalid");
        }
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

 

    function mintWithLoot(uint256 lootId) public payable nonReentrant {
        require(lockedForLooters, "Mint with loot period has finished, mint normally.");
        require(lootId > 0 && lootId <= 8000, "Token ID invalid");
        require(lootersPrice <= msg.value, "Ether value sent is not correct");
        require(lootContract.ownerOf(lootId) == msg.sender, "Not the owner of this loot");
        _safeMint(_msgSender(), lootId);
    }

   

    // Allow the DAO to claim in case some item remains unclaimed in the future
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId <= 10000, "Token ID invalid");
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

    constructor() ERC721("CastlesLootGenOne", "CastlesLootGenOne") Ownable() {}
}
