// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Dice is ERC721Enumerable, ReentrancyGuard, Ownable {

    constructor() ERC721("Dice", "DICE") Ownable() {}

    string[] private dice = [    
        "D4",
        "D6",
        "D8",
        "D10",
        "D12",
        "D20",
        "D50",
        "D100"
    ];

    uint[] private diceMod = [
        4,
        6,
        8,
        10,
        12,
        20,
        50,
        100
    ];
    
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
        "of the Frog",
        "of the Twins"
    ];
    
    string[] private namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood", "Bramble", 
        "Brimstone", "Brood", "Carrion", "Cataclysm", "Chimeric", "Corpse", "Corruption", "Damnation", 
        "Death", "Demon", "Dire", "Dragon", "Dread", "Doom", "Dusk", "Eagle", "Empyrean", "Fate", "Foe", "Fuzzy",
        "Gambler's", "Gale", "Ghoul", "Gloom", "Glyph", "Golem", "Grim", "Hate", "Havoc", "Honour", "Horror", "Hypnotic", 
        "Kraken", "Loath", "Lucky", "Maelstrom", "Magical", "Mind", "Miracle", "Morbid", "Oblivion", "Onslaught", "Pain", 
        "Pandemonium", "Phoenix", "Plague", "Rage", "Rapture", "Rune", "Skull", "Sol", "Soul", "Sorrow", 
        "Spirit", "Storm", "Tempest", "Torment", "Vengeance", "Victory", "Viper", "Vortex", "Woe", "Weighted", "Wrath",
        "Light's", "Shimmering"  
    ];
    
    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Soul",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function randomRoll(uint256 _tokenId, uint256 mod) private view returns (uint256 rndPt) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(address(msg.sender), block.timestamp, _tokenId)));
        return ((randomNum % mod) + 1);
    }
    
    function getDie(uint256 tokenId) public view returns (string memory) {
        return grabFromBag(tokenId, "DIE", dice);
    }
    
    function getDieMod(uint256 tokenId,  string memory keyPrefix, uint256[] memory sourceArray) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, uint2str(tokenId))));
        uint256 output = sourceArray[rand % sourceArray.length];
        return output;
    }
       
    function rollDie(uint256 tokenId) public view returns (string memory) {
        uint256 dieMod = getDieMod(tokenId,  "DIE", diceMod);
        return uint2str(randomRoll(tokenId, dieMod));
    }

    function grabFromBag(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, uint2str(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 12) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 15) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness != 20) {
                output = string(abi.encodePacked(name[0], ' ', name[1], " ",  output));
            } else {
                output = string(abi.encodePacked(name[0], ' ', name[1], output, " +1"));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }   .roll { fill: yellow; font-family: serif; font-size: 48px; text-decoration: underline} .block { fill: red; font-family: serif; font-size: 24px;}</style><rect width='100%' height='100%' fill='black' /><text x='10' y='40' class='base'>";

        parts[1] = getDie(tokenId);

        parts[2] = "</text><text x='10' y='175' class='base'>You rolled a:";
        
        parts[3] = "</text><text x='150' y='175' class='roll'>";

        parts[4] = rollDie(tokenId);
        
        parts[5] = "</text><text x='10' y='325' class='block'>Block: #";
         
        parts[6]= uint2str(block.number);
        
        parts[7] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));

        string memory json = string(abi.encodePacked('{"name": "Die #', uint2str(tokenId), '", "description": "Dice (for Adventurers) are randomized dice for your adventuring stories. Everytime you refresh the metadata, you will get a new rolled number based on your die. Feel free to use Dice in any way you want.", "image_data": "', output, '", "attributes": [ {"trait_type": "Type", "value": "' ,  getDie(tokenId), '"}, {"trait_type": "Roll", "value": "', parts[4], '"}]}'));
        output = string(abi.encodePacked('data:application/json;utf8,', json));

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

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}