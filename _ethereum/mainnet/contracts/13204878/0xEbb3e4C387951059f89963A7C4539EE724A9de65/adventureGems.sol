// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * @title AdventureGems contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract AdventureGems is ERC721, ReentrancyGuard, Ownable {
    
    uint256 public s_publicPrice = 20000000000000000; //0.02 ETH
    bool public s_isPrivateSale = true;

    mapping(uint256=>uint256) private s_randomSeeds;
    //Loot Interface
    LootInterface lootContract;
        
    struct gemDataStruct {
        string condition;
        string stone;
        string size;
        string suffix;
        string cut;
        string jewelryType;
        string power;
        string protection;
        string effect;
        string colourHSL;
        string blessing;
    }

    constructor(address p_loot) ERC721("Adventure Gems for Loot", "ADVGEM") {
        lootContract = LootInterface(p_loot);
    }
    
    function setLootContract (address p_lootContract) onlyOwner external {
        lootContract = LootInterface(p_lootContract);
    }
    
    /* GET FUNCTIONS */
    
    function getGemStone(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");           
        uint256 gemId = findGemId(p_tokenId, "GEMSTONE");
        string[8] memory gemStoneNames = [
            "Blue Diamond",
            "Pink Diamond",
            "Diamond",
            "Ruby",
            "Emerald",
            "Sapphire",            
            "Jade",
            "Opal"
        ];
        return gemStoneNames[gemId];
    }
        
    function getGemCondition(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");         
        uint256 conditionId = findGemId(p_tokenId, "CONDITION");
        string[8] memory gemConditionNames = [
            "Divine",
            "Sacred",
            "Legendary",
            "Sterling",
            "Brilliant",
            "Radiant",
            "Shiny",
            "Worn"
        ];
        return gemConditionNames[conditionId];
    }
    
    function getGemSize(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");           
        uint256 gemSizeId = findGemId(p_tokenId, "GEMSIZE");
        string[8] memory gemSizes = [
            "Huge",
            "Large",
            "Larger than average",
            "Average",
            "Average",
            "Smaller than average",       
            "Small",
            "Tiny"
        ];
        return gemSizes[gemSizeId];
    }
    
    function getGemColourHSL(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");          
        uint256 conditionId = findGemId(p_tokenId, "CONDITION");
        uint256 gemId = findGemId(p_tokenId, "GEMSTONE");
        uint8[8] memory gemSaturations = [
            100, // Divine
            80, // Blessed
            70, // Sacred
            60, // Exalted
            50, // Brilliant
            40, // Radiant
            30, // Shiny
            20 // Worn
        ];
        uint16[8] memory gemHues = [
            220, // Blue diamond
            300, // Pink diamond
            0, // Diamond
            0, // Ruby
            120, // Emerald
            40, // Sapphire
            180, // Jade
            20 // Opal
        ];
        uint8[8] memory gemLightnesses = [
            50, // Blue diamond
            50, // Pink diamond
            100, // Diamond
            50, // Ruby
            50, // Emerald
            50, // Sapphire
            50, // Jade
            80 // Opal
        ];

        string memory output = string(abi.encodePacked(toString(uint256(gemHues[gemId])),
            ',',
            toString(uint256(gemSaturations[conditionId])),
            '%,',
            toString(uint256(gemLightnesses[gemId])),
            '%'));
        return output;
    }
    
    function getGemPowerSuffix(uint256 p_tokenId) public view returns (string memory) {
       require(_exists(p_tokenId),"Not minted");       
        uint256 powerId = findGemPowerId(p_tokenId, "POWER");
        string[13] memory gemPowerNames = [
            "the Gods",
            "Eternal Youth",
            "Healing Light",
            "the Warrior",
            "Dexterity",
            "Thieves",
            "Fortune",
            "Ancient Wisdom",
            "Immolation",
            "Thunder",
            "the Seas",
            "the Skies",
            "the Earth"
        ];
        return gemPowerNames[powerId];
    }
    
    function getGemPower(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");        
        uint256 powerId = findGemPowerId(p_tokenId, "POWER");
        string[13] memory gemBoost = [
            "Wisdom",
            "Charisma",
            "Constitution",
            "Strength",
            "Dexterity",
            "Stealth",
            "Critical Strikes",
            "Intelligence",
            "Fire dmg",
            "Lightning dmg",
            "Water dmg",
            "Wind dmg",
            "Earth dmg"];
        return gemBoost[powerId];
    }
    
    function getGemProtection(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");        
        uint256 powerId = findGemPowerId(p_tokenId, "PROTECT");
        string[13] memory gemProtection = [
            "Magic",
            "Encounters",
            "Critical Strikes",
            "Poison",
            "Blunt Weapons",
            "Ranged Weapons",
            "Confusion",
            "Fire",
            "Lightning",
            "Water",
            "Wind",
            "Earth",
            "Stealing"
            ];
        return gemProtection[powerId];
    }
    
    function getGemEffect(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string[17] memory gemEffect = [
            "looks indestructible",
            "hypnotizes",
            "entrances",
            "whispers eerily",
            "glows under the moon",
            "looks a bit scary",
            "glows in the dark",
            "feels hot",
            "feels cold",
            "glows under a full moon",
            "looks durable",
            "feels heavy",
            "feels light",
            "vibrates",
            "resists water",
            "looks otherworldy",
            "smells strange"];
        uint256 rand = random(abi.encodePacked("EFFECT", s_randomSeeds[p_tokenId]));
        uint256 effectId = (rand % gemEffect.length);
        return gemEffect[effectId];
    }
    
    function getGemCut(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string[10] memory gemCuts = [
            "Heart",
            "Teardrop",
            "Oval",
            "Round",
            "Rectangular",
            "Triangle",
            "Hexagon",
            "Trillion",
            "Octagon",
            "Marquise"
            ];
        uint256 rand = random(abi.encodePacked("CUT", s_randomSeeds[p_tokenId]));
        uint256 cutId = (rand % gemCuts.length);
        return gemCuts[cutId];
    }
    
    function getGemBlessing(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string memory output="No blessing";
        uint256 conditionId = findGemId(p_tokenId, "CONDITION");
        // Only for divine gems
        if (conditionId==0) {
            string[10] memory rarities = [
            "Scares away monsters",
            "Doubles stamina",
            "Doubles damage output",
            "Attracts monsters",
            "Doubles move speed",
            "Grants fire immunity",
            "Dodges critical strikes",
            "Regenerates health",
            "Doubles earned experience",
            "Doubles gold drops"
            ];
            uint256 rand = random(abi.encodePacked("BLESSING", s_randomSeeds[p_tokenId]));
            uint256 rarityId = (rand % rarities.length);
            output = rarities[rarityId];
        }
        return output;
    }
    
    
    function getJewelryType(uint256 p_tokenId) public view returns (string memory) {
        require(_exists(p_tokenId),"Not minted");
        string[7] memory jewelryTypes = [
            "Amulet",
            "Ring",
            "Necklace",
            "Pendant",
            "Bracelet",
            "Earring",
            "Locket"];
        uint256 rand = random(abi.encodePacked("JEWEL", s_randomSeeds[p_tokenId]));
        uint256 r_attrId = (rand % jewelryTypes.length);
        return jewelryTypes[r_attrId];
    }  

    // FINDER functions
    // Find Gem Id can find anything from an array with 8 elements (note: weighting table in place)
    function findGemId(uint256 p_tokenId, string memory p_seedString) internal view returns (uint256) {
        uint8[8] memory weightings = [
            1,
            2,
            4,
            8,
            16,
            32,
            56,
            78
        ];
        uint256 rand = random(abi.encodePacked(p_seedString, s_randomSeeds[p_tokenId]));
        uint256 weighting = (rand % 100)+1;
        uint256 r_attrId = weightings.length-1;
        for (uint i=0; i<weightings.length-1; i++) {
            if (weighting>=weightings[i] && weighting<weightings[i+1]) {
                r_attrId = i;
            }
        }
        return r_attrId;
    }
    
    // Find Gem Power can find anything from an array with 13 elements (note: weighting table in place)
    function findGemPowerId(uint256 p_tokenId, string memory p_seedPhrase) internal view returns (uint256) {
         uint8[13] memory weightings = [
            1,
            4,
            7,
            10,
            15,
            20,
            25,
            30,
            45,
            55,
            65,
            75,
            85
        ];
        uint256 rand = random(abi.encodePacked(p_seedPhrase, s_randomSeeds[p_tokenId]));
        uint256 weighting = (rand % 100)+1;
        uint256 r_attrId = weightings.length-1;
        for (uint i=0; i<weightings.length-1; i++) {
            if (weighting>=weightings[i] && weighting<weightings[i+1]) {
                r_attrId = i;
            }
        }
        return r_attrId;
    }
    
    
    /* Token URI encoder */

    function tokenURI(uint256 p_tokenId) override public view returns (string memory) {
        gemDataStruct memory gemData;

        gemData.condition = getGemCondition(p_tokenId);
        gemData.stone = getGemStone(p_tokenId);
        gemData.size = getGemSize(p_tokenId);
        gemData.suffix = getGemPowerSuffix(p_tokenId);
        gemData.cut = getGemCut(p_tokenId);
        gemData.jewelryType = getJewelryType(p_tokenId);
        gemData.power = getGemPower(p_tokenId);
        gemData.protection = getGemProtection(p_tokenId);
        gemData.effect = getGemEffect(p_tokenId);
        gemData.colourHSL = getGemColourHSL(p_tokenId);
        gemData.blessing = getGemBlessing(p_tokenId);
        
        string memory output;

        // Need to do this to prevent stack depth errors
        output = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }.colored { fill:hsl(',
            gemData.colourHSL,
            ')}</style><rect width="100%" height="100%" fill="black" stroke="hsl(',
            gemData.colourHSL,
            ')" stroke-width="5px" /><text x="10" y="20" class="base colored" font-weight="bold">',
            string(abi.encodePacked(gemData.condition," ",gemData.stone," ",gemData.jewelryType," of ", gemData.suffix)),
            '</text><text x="10" y="60" class="base colored">',
            gemData.stone,
            '</text><text x="10" y="80" class="base">'
        ));

        output = string(abi.encodePacked(
            output,
            gemData.condition,
            '</text><text x="10" y="100" class="base">',
            gemData.size,
            '</text><text x="10" y="120" class="base">',
            gemData.cut,
            '</text><text x="10" y="140" class="base">',
            gemData.jewelryType,
            '</text><text x="10" y="180" class="base">Boosts ',
            gemData.power,
            '</text><text x="10" y="200" class="base">Protects against '));

        output = string(abi.encodePacked(
            output,
            gemData.protection,
            '</text><text x="10" y="220" class="base">It ',
            gemData.effect,
            '</text><text x="10" y="260" class="base colored">',
            gemData.blessing,            
            '</text><text text-anchor="end" x="95%" y="95%" class="base">#',
            toString(p_tokenId),
            '</text></svg>'));

        string memory attributes = string(abi.encodePacked(
            '{"trait_type":"gem","value":"',gemData.stone,
            '"},{"trait_type":"condition","value":"',gemData.condition,
            '"},{"trait_type":"cut","value":"',gemData.cut,
            '"},{"trait_type":"jewelry","value":"',gemData.jewelryType,
            '"},{"trait_type":"namesuffix","value":"',gemData.suffix,
            '"},{"trait_type":"power","value":"',gemData.power,
            '"},{"trait_type":"protection","value":"',gemData.protection
        ));
        
        attributes = string(abi.encodePacked(
            attributes,
            '"},{"trait_type":"effect","value":"',gemData.effect,
            '"},{"trait_type":"size","value":"',gemData.size,
            '"},{"trait_type":"blessing","value":"',gemData.blessing,'"}'
        ));
            
    
        string memory json = Base64.encode(bytes(
            string(abi.encodePacked(
                '{"name": "Jewelry #', 
                toString(p_tokenId),
                '","description": "Loot Jewels for Adventurers are generated and stored on chain. Stats, images, and other functionality are omitted for others to interpret. Use however you want.",', 
                '"image": "data:image/svg+xml;base64,', 
                Base64.encode(bytes(output)),
                '","attributes": [', attributes, ']}'
            ))
        ));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    
    // Loot minting (free)
    function mintWithLoot(uint p_lootId) public payable nonReentrant {
        require(lootContract.ownerOf(p_lootId) == msg.sender, "Not loot owner");
        _safeMint(msg.sender, p_lootId);
        s_randomSeeds[p_lootId] = uint256(blockhash(block.number - 2))
            ^ block.timestamp
            ^ block.difficulty 
            ^ p_lootId
            ^ block.basefee
            ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
    }
    
    function multiMintWithLoot(uint[] memory p_lootIds) public payable nonReentrant {
        for (uint i=0; i<p_lootIds.length; i++) {
            require(lootContract.ownerOf(p_lootIds[i]) == msg.sender, "Not loot owner");
            _safeMint(msg.sender, p_lootIds[i]);
            s_randomSeeds[p_lootIds[i]] = uint256(blockhash(block.number - 2))
                ^ block.timestamp 
                ^ block.difficulty 
                ^ p_lootIds[i] 
                ^ block.basefee
                ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
        }
    }
    
    // Public minting
    function mint(uint p_tokenId) public payable nonReentrant {
        require(s_publicPrice <= msg.value, "Insufficient Ether");
        if (s_isPrivateSale){
            require(p_tokenId > 8000 && p_tokenId <= 12000, "Token ID invalid");
        } else {
            require(p_tokenId > 0 && p_tokenId <= 12000, "Token ID invalid");
        }
        _safeMint(msg.sender, p_tokenId);
        s_randomSeeds[p_tokenId] = uint256(blockhash(block.number - 2))
            ^ block.timestamp
            ^ block.difficulty
            ^ p_tokenId
            ^ block.basefee
            ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
    }
    
    function multiMint(uint[] memory p_tokenIds) public payable nonReentrant {
        require((s_publicPrice * p_tokenIds.length) <= msg.value, "Insufficient Ether");
        
        for (uint i=0; i<p_tokenIds.length; i++) {
            if (s_isPrivateSale){
                require(p_tokenIds[i] > 8000 && p_tokenIds[i] <= 12000, "Token ID invalid");
            } else {
                require(p_tokenIds[i] > 0 && p_tokenIds[i] <= 12000, "Token ID invalid");
            }
            _safeMint(msg.sender, p_tokenIds[i]);
            s_randomSeeds[p_tokenIds[i]] = uint256(blockhash(block.number - 2))
                ^ block.timestamp
                ^ block.difficulty
                ^ p_tokenIds[i]
                ^ block.basefee
                ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
        }
    }    
    
    // Owner reserved minting (100 items)
     function ownerMint(uint p_tokenId) public payable nonReentrant onlyOwner {
         require(p_tokenId > 12000 && p_tokenId <= 12100, "Token ID invalid");
        _safeMint(msg.sender, p_tokenId);         
        s_randomSeeds[p_tokenId] =  uint256(blockhash(block.number - 2))
            ^ block.timestamp
            ^ block.difficulty
            ^ p_tokenId
            ^ block.basefee
            ^ uint256(keccak256(abi.encodePacked(block.coinbase)));
        
     }
    
    /* UTILITY FUNCTIONS */
    
    function flipPrivateSale() external onlyOwner {
        s_isPrivateSale = !s_isPrivateSale;
    }
    
    function setPrice(uint256 p_newPrice) external onlyOwner {
        s_publicPrice = p_newPrice;
    }
    
    function random(bytes memory p_input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(p_input)));
    }
    
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function deposit() public payable onlyOwner {}


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