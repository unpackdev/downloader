// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract CardGame is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 44444;
    uint256 public constant MAX_BY_MINT = 15;

    event CreateCard(uint256 indexed id);

    constructor() ERC721("CardGame", "CG") Ownable() {}

    string[] private cardTypes = [
        "creature", "item", "place", "spell"
    ];

    string[] private creatureNamePrefixes = [
        "Confused", "Flying", "Lost", "Lingering", "Raging", "Silent", "Stalking", 
        "Stumbling", "Wandering", "Whimsical"
    ];

    string[] private creatureNameNouns = [
        "Alien", "Ape", "Bear", "Beast", "Bull", "Cat", "Dog", "Dragon", 
        "Druid", "Elemental", "Elf", "Giant", "Goblin", "Golem", "Horror", 
        "Human", "Insect", "Leviathan", "Minotaur", "Penguin", "Skeleton", 
        "Soul", "Spider", "Spirit", "Zombie", "Wolf"
    ];

    string[] private creatureAbilities = [
        "Bridging", "Feint", "Immobile", "Landcrawler"
    ];

    string[] private itemNameAdjectives = [
        "Gigantic", "Golden", "Heavy", "Intriguing", "Mythical", 
        "Perplexing", "Rainbow", "Shadow", "Worn"
    ];

    string[] private itemNameNouns = [
        "Book", "Bottle", "Box", "Compass", "Couch", "Cross", "Egg", "Flag", 
        "Lance", "Locket", "Prism", "Rug", "Stone", "Table"
    ];

    string[] private itemAbilities = [
        "Cherished", "Magestic", "Neglected", "Packed"
    ];

    string[] private spellNameAdjectives = [
        "Animating", "Chain", "Cosmic", "Dissolving", "Electric", "Engrossing", 
        "Geodial", "Intense", "Noxious", "Powerful", "Psychic", "Tormenting", 
        "Volcanic"
    ];

    string[] private spellNameNouns = [
        "Blast", "Bolt", "Clouds", "Flood", "Gas", "Lava", "Lightning", "Ritual",
        "Spark", "Storm", "Tremors", "Zap"
    ];

    string[] private spellAbilities = [
        "Binding", "Countercast", "Fizzle", "Lingering"
    ];

    string[] private placeNameAdjectives = [
        "Blessed", "Dark", "Ghostly", "Shimmering", "Vivid"
    ];

    string[] private placeNameNouns = [
        "Canopy", "Cascades", "Crag", "Etheria", "Forest", "Islands", "Mirage",
        "Moons", "Mountain", "Pools", "Plains", "Prison", "Swamp", "Volcano"
    ];

    string[] private placeAbilities = [
        "Bountiful", "Convergent", "Ephemeral", "Planar"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getTypeId(uint256 tokenId) public view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("Type", toString(tokenId))));
        return rand % cardTypes.length;
    }

    function getType(uint256 tokenId) public view returns (string memory) {
        return cardTypes[getTypeId(tokenId)];
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        uint256 cardType = getTypeId(tokenId);

        if (cardType == 0)  {
            return string(abi.encodePacked(
                pluck(tokenId, "CreatureNamePrefix", creatureNamePrefixes),
                " ",
                pluck(tokenId, "CreatureNameNoun", creatureNameNouns)
            ));
        }
        if (cardType == 1) {
            return string(abi.encodePacked(
                pluck(tokenId, "ItemNameAdjective", itemNameAdjectives),
                " ",
                pluck(tokenId, "ItemNameNoun", itemNameNouns)
            ));
        }
        if (cardType == 2) {
            return string(abi.encodePacked(
                pluck(tokenId, "PlaceNameAdjective", placeNameAdjectives),
                " ",
                pluck(tokenId, "PlaceNameNoun", placeNameNouns)
            ));
        }
        if (cardType == 3) {
            return string(abi.encodePacked(
                pluck(tokenId, "SpellNameAdjective", spellNameAdjectives),
                " ",
                pluck(tokenId, "SpellNameNoun", spellNameNouns)
            ));
        }
        return "";
    }

    function getAbility(uint256 tokenId, uint256 position) public view returns (string memory) {
        uint256 cardType = getTypeId(tokenId);
        uint256 rand = random(string(abi.encodePacked("Ability", toString(tokenId))));
        uint256 randAbility = random(string(abi.encodePacked("Ability", toString(tokenId)))) + position;
        uint chanceToShow = (((4 ** position) * 10000)  / (10 ** position)); // 40% chance for each additional ability to be chosen
        if (rand % 10000 > chanceToShow) {
            return "";
        }
        if (cardType == 0) {
            return creatureAbilities[randAbility % creatureAbilities.length];
        }
        if (cardType == 1) {
            return itemAbilities[randAbility % itemAbilities.length];
        }
        if (cardType == 2) {
            return placeAbilities[randAbility % placeAbilities.length];
        }
        if (cardType == 3) {
            return spellAbilities[randAbility % spellAbilities.length];
        }
        return "";
    }
    
    function getStat(uint256 tokenId, uint256 position) public pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("Number", position, "-", toString(tokenId))));
        return  rand % 10; 
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("CardGame-Alpha", keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[22] memory parts = [
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 200 250"><style>.base { fill: white; font-family: arial,sans-serif; font-size: 12px; } </style><rect width="200px" height="250px" fill="black" />',
            '<text x="100" y="45" class="base" text-anchor="middle">',
            getName(tokenId),
            '</text><text x="100" y="65" class="base" text-anchor="middle">',
            getType(tokenId),
            '</text><text x="10" y="20" class="base">',
            toString(getStat(tokenId, 0)),
            '</text><text x="185" y="20" class="base">',
            toString(getStat(tokenId, 1)),
            '</text><text x="10" y="240" class="base">',
            toString(getStat(tokenId, 2)),
            '</text><text x="185" y="240" class="base">',
            toString(getStat(tokenId, 3)),
            '</text><text x="20" y="110" class="base">',
            getAbility(tokenId, 1),
            '</text><text x="20" y="130" class="base">',
            getAbility(tokenId, 2),
            '</text><text x="20" y="150" class="base">',
            getAbility(tokenId, 3),
            '</text><text x="20" y="170" class="base">',
            getAbility(tokenId, 4),
            '</text></svg>'
        ];

        string memory output;
        
        for (uint i = 0; i < parts.length; i++) {
            output = string(abi.encodePacked(output, parts[i]));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Card #',
                        toString(tokenId),
                        '", "description": "Randomized cards generated and stored on chain. Gameplay, rules, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Card Game in any way you want..", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }
    
    function mint(address _to, uint256 _count) public payable {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(_count <= MAX_BY_MINT, "Minting too many");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateCard(id);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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