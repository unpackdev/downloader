/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PerksForAdventurers is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    using Counters for Counters.Counter;
    
    uint256 public price = 20000000000000000; //0.02 ETH
    // address public multisigAddress = 0x31AB89af718f141D63cEE3b51f50DB8f375d2d0B; //testnet
    address public multisigAddress = 0xDb9E7c04378299048DD1882F6c9Cf21d709f9319; //mainnet

    uint256 public constant MAX_SYNTHETIC_ITEMS = 2000;
    Counters.Counter private _syntheticItemsTracker;
    Counters.Counter private _originItemsTracker;

    //Loot Contract
    address public lootAddress;
    LootInterface lootContract;

    // address proxyRegistryAddress = 0xF57B2c51dED3A29e6891aba85459d600256Cf317; //testnet
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; //mainnet
           
    event CreatePerk(uint256 indexed id);
		
    string[] private traits = [
        'Lightning Reflexes',
        'Eagle-eyes',
        'Excellent Judgement',
        'Heightened Senses',
        'Awareness',
        'Faster Healing',
        'Night Vision',
        'Toughness',
        'Educated',
        'Silent Running',
        'Strong Back',
        'Camouflage',
        'Heightened Smell',
        'Heightened Taste',
        'Heightened Hearing',
        'Computer Expert',
        'Stealth',
        'Swimmer',
        'Vehicle Mastery',
        'Rock Climbing',
        'Communicator',
        'Leadership',
        'Collaborator',
        'Military General',
        'Strategic Planner',
        'X-Ray Vision'
    ];
    
    string[] private traits2 = [
        'Speed',
        'Strength',
        'Stamina',
        'Intelligence',
        'Dexterity',
        'Agility'
    ];

    string[] private fightingPerks = [
'Samurai Master',
'Sniping Accuracy',
'Quick Draw Weapons',
'Nunchuk Practioner',
'Karate',
'Brazilian Jiu-Jitsu',
'Archery',
'Throwing Weapons Practioner',
'Dagger Proficiency',
'Explosives Proficiency',
'Swordsman',
'Axe Proficiency',
'Vampire Teeth',
'Venom Glands',
'Quick Dash',
'Trap Proficiency',
'Horse Riding',
'Dual-Wielding',
'Firearms Proficiency'
    ];
    
    string[] private defensePerks = [
'Earth Resistance',
'Flame Resistance',
'Water Resistance',
'Storm Resistance',
'Air Resistance',
'Animal Resistance',
'Monster Resistance',
'Magic Resistance',
'Poison Immunity',
'Elemental Absorption',
'Death Ward',
'Magic Armour',
'Mirror Image',
'Physical Barrier',
'Magic Barrier',
'Diamond Skin'
    ];
    

    string[] private magicPerks = [
'Teleportation',
'Mind reading',
'Earth Touched',
'Flame Touched',
'Water Touched',
'Storm Touched',
'Air Touched',
'Healing',
'Astral Projection',
'Invisibility',
'Shapeshifting',
'Forcefield',
'Phasing',
'Time Dilation',
'Time Travel',
'Size Enhancement',
'Size Reduction',
'Laser Beams',
'Health Regeneration ',
'Invulnerability',
'Telepathy',
'Telekinesis',
'Spirit Walker',
'Levitation'
    ];

    					

    string[] private survivalPerks = [
'Firestarter',
'Medic',
'Fishing',
'Wood Cutter',
'Attraction',
'Acrobat',
'Animal Handler',
'Persuasion',
'Intimidation',
'Stealth',
'Retreat',
'Camoflague',
'Furious Charge',
'Smoke Screen',
'Strafe',
'Death Dodger'
    ];

			 	

    string[] private craftingPerks = [
'Potion Brewer',
'Elixer Brewer',
'Alchemist',
'Chef',
'Leathersmith',
'Blacksmith',
'Craftsman',
'Hunter',
'Fisherman',
'Weaver',
'Greenskeeper',
'Goldsmith',
'Miner',
'Slingshot Crafter',
'Farmer',
'Mechanic',
'Trench Digger',
'Trap Builder',
'Firearms Crafter',
'Bow Crafter',
'House Builder'
    ];
    
    			

    string[] private flawedPerks = [
'Panicked',
'Fearful',
'Addict',
'Cursed',
'Glutton',
'Gulilible',
'Illiterate',
'Lazy',
'Murderer',
'Pacifist',
'Ugly',
'Unlucky',
'Bloodlust',
'Coward',
'Greedy',
'Sickly',
'Follower',
'Rebellious',
'Vanity',
'Vengeful',
'Overconfident',
'Superstitious',
'Spoiled'
    ];
    
    string[] private traitPrefixes = [
       "Minor Boost of",
       "Greater Boost of",
       "Superior Boost of",
       "Supreme Boost of"
    ];	

    string[] private perkPrefixes = [
       "Novice",
       "Intermediate",
       "Expert",
       "Mastered"
    ];

    string[] private perkSkillPrefixes = [
       "Novice",
       "Intermediate",
       "Advanced",
       "Ultimate"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getTrait1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TRAIT", traits);
    }
    
    function getTrait2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TRAIT 2", traits2);
    }
    
    function getFightingPerk(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FIGHTING", fightingPerks);
    }
    
    function getDefensePerk(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DEFENSE", defensePerks);
    }
    
    function getMagicPerk(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MAGIC", magicPerks);
    }

    function getSurvivalPerk(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SURVIVAL", survivalPerks);
    }
    
    function getCraftingPerk(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CRAFTING", craftingPerks);
    }
    
    function getFlawedPerk(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FLAW", flawedPerks);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint256 rarity = rand % 101;
        string memory traitRarity = "";
        string memory perkRarity = "";
        string memory output = sourceArray[rand % sourceArray.length];
        string[] memory prefix = perkSkillPrefixes;
        
        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256(abi.encodePacked("TRAIT")) ){
            output = string(abi.encodePacked(output));
        } else if(keccak256(abi.encodePacked(keyPrefix)) == keccak256(abi.encodePacked("TRAIT 2")) ) {
            if (0 < rarity && rarity <= 60){
                traitRarity = traitPrefixes[0];
            } else if (60 < rarity && rarity <= 90 ){
                traitRarity = traitPrefixes[1];
            } else if (90 < rarity && rarity <= 98 ){
                traitRarity = traitPrefixes[2];
            } else {
                traitRarity = traitPrefixes[3];
            }
            output = string(abi.encodePacked(traitRarity, " ", output));
        } else if(keccak256(abi.encodePacked(keyPrefix)) != keccak256(abi.encodePacked("FLAW")) ) {
            
            if(keccak256(abi.encodePacked(keyPrefix)) == keccak256(abi.encodePacked("FIGHTING")) || 
            keccak256(abi.encodePacked(keyPrefix)) == keccak256(abi.encodePacked("CRAFTING")) ) {
                prefix = perkPrefixes;
            }
            
            if (0 < rarity && rarity <= 60 ){
                perkRarity = prefix[0];
            } else if (60 < rarity && rarity <= 90 ){
                perkRarity = prefix[1];
            } else if (90 < rarity && rarity <= 98 ){
                perkRarity = prefix[2];
            } else {
                perkRarity = prefix[3];
            }
            output = string(abi.encodePacked(perkRarity, " ", output));
        }
        
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getTrait1(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getTrait2(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getFightingPerk(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getDefensePerk(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getMagicPerk(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getSurvivalPerk(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getCraftingPerk(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getFlawedPerk(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        
        string memory json = string(abi.encodePacked('{',
            '"name": "Perk Bag #', toString(tokenId), '", ',
            '"description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", ',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '",'));
            
        string memory attributes = string(abi.encodePacked('"attributes": [',
            '{"trait_type": "Raw Trait", "value": "', parts[1], '" },',
            '{"trait_type": "Raw Trait 2", "value": "', parts[3], '" },',
            '{"trait_type": "Fighting", "value": "', parts[5], '" },',
            '{"trait_type": "Defense", "value": "', parts[7], '" },'));
        
        attributes = string(abi.encodePacked(attributes,
            '{"trait_type": "Magic", "value": "', parts[9], '" },',
            '{"trait_type": "Survival", "value": "', parts[11], '" },',
            '{"trait_type": "Crafting", "value": "', parts[13], '" },',
            '{"trait_type": "Flawed", "value": "', parts[15], '" }]'));
            
        string memory json_end = string(abi.encodePacked('}'));
        json = string(abi.encodePacked(json, attributes, json_end));
        output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));

        return output;
    }

    function _totalSyntheticSupply() internal view returns (uint) {
        return _syntheticItemsTracker.current();
    }
    
    function totalSyntheticSupply() public view returns (uint256) {
        return _totalSyntheticSupply();
    } 
    
    function _totalOriginSupply() internal view returns (uint) {
        return _originItemsTracker.current();
    }
    
    function totalOriginSupply() public view returns (uint256) {
        return _totalOriginSupply();
    } 
    
   function mint(uint256 tokenId) public payable nonReentrant {
        require(!_exists(tokenId), "This token has already been minted");
        require(tokenId > 0 && tokenId <= 10000, "Invalid token id");
        bool isLootOrigin = tokenId > 0 && tokenId <= 8000;
        if(isLootOrigin) {
            require(lootContract.ownerOf(tokenId) == _msgSender(), "Not the owner of this loot");
            _originItemsTracker.increment();
        } else {
            require(price <= msg.value, "Ether value sent is not correct");
            uint256 total = _totalSyntheticSupply();
            require(total + 1 <= MAX_SYNTHETIC_ITEMS, "Max limit");
            _syntheticItemsTracker.increment();
        }
        _safeMint(_msgSender(), tokenId);
        emit CreatePerk(tokenId);
    }
 
    function mintOwner(uint256 tokenId) public nonReentrant onlyOwner {
        _safeMint(multisigAddress, tokenId);
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

    function withdraw() public onlyOwner{
        (bool success, ) = payable(multisigAddress).call{ value: (address(this).balance), gas: 100000 }("");
        require(success, "Failed to send Ether");
    }
    
    function setMultiSigAddress(address multisig) public onlyOwner {
        multisigAddress = multisig;
    }
    
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    
    constructor(address loot) ERC721("Perks (for Adventurers)", "PERKS") {
        lootAddress = loot;
        lootContract = LootInterface(loot);
    }
}