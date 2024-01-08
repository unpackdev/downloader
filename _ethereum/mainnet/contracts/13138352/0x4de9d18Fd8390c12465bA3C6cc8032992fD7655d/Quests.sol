// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract Quests is ERC721Enumerable, Ownable, ReentrancyGuard {

    ERC721 loot = ERC721(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);

    string[] private questWord0 = [
        "Abandoned",
        "Blind",
        "Broken",
        "Charming",
        "Corrupt",
        "Cruel",
        "Cursed",
        "Damned",
        "Deadly",
        "Disappearing",
        "Drunken",
        "Evil",
        "Fading",
        "Forgotten",
        "Hidden",
        "Legendary",
        "Lingering",
        "Lost",
        "Menacing",
        "Sacred",
        "Smelly",
        "Sticky",
        "Stolen",
        "Terrible"
        "Toxic"
    ];

    string[] private questWord1 = [
        "Journal",
        "Map",
        "Secret",
        "Trials",
        "Fate",
        "Innocence",
        "Legion",
        "Lore",
        "Puzzle",
        "Barter",
        "End",
        "Legacy",
        "Maze",
        "Cult",
        "Blade",
        "Mystery",
        "Ritual",
        "Fury",
        "Spell",
        "Curse",
        "Conspiracy",
        "Night",
        "Circle",
        "Avatar",
        "Castle"
        "Guild",
        "Nightmare",
        "Destiny",
        "Plague",
        "Song",
        "Prophecy",
        "Crown",
        "Gem",
        "Key",
        "Treasure"
    ];

    string[] private questWord2 = [
        "Izith",
        "Edali",
        "Refora",
        "Adeis",
        "Omaxaryl",
        "Ixius",
        "Togron",
        "Proxon",
        "Juwyn",
        "Moryen",
        "Fenhorn",
        "Sylvaris",
        "Valtris",
        "Urimys",
        "Thefir",
        "Keafaren",
        "Glynydark",
        "Benmek"
        "Thorrom",
        "Theldain"
        "Bunthran",
        "Brilgiel",
        "Gwanra",
        "Nasnas",
        "Daerwyn",
        "Bazur",
        "Klog",
        "Karguk",
        "Bor",
        "Homraz",
        "Nargol",
        "Snak",
        "Mor"
    ];

    string[] private actions = [
        "Kiss the princess",
        "Kiss the prince",
        "Swim with the merfolk",
        "Sneak into the dungeon",
        "Sail with pirates",
        "Infiltrate the City Watch",
        "Pay the toll to the troll",
        "Duel the Black Knight",
        "Ride your steed",
        "Trap the genie in its bottle",
        "Solve the murder",
        "Collect the unicorn's horn",
        "Flirt with the innkeeper",
        "Join the Thieves' Guild",
        "Trial by combat",
        "Avenge your father",
        "Steal from the rich",
        "Give to the poor",
        "Take a long rest",
        "Stay awhile and listen",
        "Drink all the mead",
        "Befriend the elves",
        "Mine with dwarves",
        "Inspire a bard",
        "Cast lightning bolt",
        "Grow a wizard's beard",
        "Revive a fallen comrade"
    ];

    string[] private rareActions = [
        "Slay the Dragon",
        "Save the World",
        "Find the Holy Grail",
        "Make a Wish",
        "Become the King",
        "Pull the Sword from the Stone"
    ];

    constructor() ERC721("Quests", "QUESTS") Ownable() {}
    
    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 8000 && tokenId < 10001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
        _safeMint(_msgSender(), tokenId + 10000);
        _safeMint(_msgSender(), tokenId + 20000);
        _safeMint(_msgSender(), tokenId + 30000);
        _safeMint(_msgSender(), tokenId + 40000);
    }

    function claimForLoot(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        require(loot.ownerOf(tokenId) == msg.sender, "Not Loot owner");
        _safeMint(_msgSender(), tokenId);
        _safeMint(_msgSender(), tokenId + 10000);
        _safeMint(_msgSender(), tokenId + 20000);
        _safeMint(_msgSender(), tokenId + 30000);
        _safeMint(_msgSender(), tokenId + 40000);
    }
    
    function getQuestName(uint256 tokenId) public view returns (string memory) {
        require(tokenId < 10001, "Token ID invalid");
        string[3] memory parts;
        uint256 rand0 = random(string(abi.encodePacked(toString(tokenId), "0")));
        parts[0] = questWord0[rand0 % questWord0.length];
        uint256 rand1 = random(string(abi.encodePacked(toString(tokenId), "1")));
        parts[1] = questWord1[rand1 % questWord1.length];
        uint256 rand2 = random(string(abi.encodePacked(toString(tokenId), "2")));
        parts[2] = questWord2[rand2 % questWord2.length];
        return string(abi.encodePacked("The ", parts[0], " ", parts[1], " of ", parts[2]));
    }

    function getQuestActions(uint256 tokenId) public view returns (string[4] memory) {
        string[4] memory questActions;

        uint256 rand1 = random(string(abi.encodePacked(toString(tokenId), "1")));
        if (rand1 % 21 == 0) {
            questActions[0] = rareActions[rand1 % rareActions.length];
        } else {
            questActions[0] = actions[rand1 % actions.length];
        }
        
        uint256 rand2 = random(string(abi.encodePacked(toString(tokenId), "2")));
        if (rand2 % 21 == 0) {
            questActions[1] = rareActions[rand2 % rareActions.length];
        } else {
            questActions[1] = actions[rand2 % actions.length];
        }
        
        uint256 rand3 = random(string(abi.encodePacked(toString(tokenId), "3")));
        if (rand3 % 21 == 0) {
            questActions[2] = rareActions[rand3 % rareActions.length];
        } else {
            questActions[2] = actions[rand3 % actions.length];
        }

        uint256 rand4 = random(string(abi.encodePacked(toString(tokenId), "4")));
        if (rand4 % 21 == 0) {
            questActions[3] = rareActions[rand4 % rareActions.length];
        } else {
            questActions[3] = actions[rand4 % actions.length];
        }

        return questActions;
    }

    function getAction(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(toString(tokenId)));
        if (rand % 21 == 0) {
            return rareActions[rand % rareActions.length];
        } else {
            return actions[rand % actions.length];
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (tokenId < 10001) {
            return questTokenUri(tokenId);
        } else {
            return actionTokenUri(tokenId);
        }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function questTokenUri(uint256 tokenId) internal view returns (string memory) {
        string[4] memory questActions = getQuestActions(tokenId);
        string[11] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base" text-decoration="underline">';

        parts[1] = getQuestName(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = questActions[0];

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = questActions[1];

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = questActions[2];

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = questActions[3];

        parts[10] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', parts[1], '", "description": "Quests.", "attributes": [ { "trait_type": "Step 1", "value": "', questActions[0], '" }, { "trait_type": "Step 2", "value": "', questActions[1], '" }, { "trait_type": "Step 3", "value": "', questActions[2], '" }, { "trait_type": "Step 4", "value": "', questActions[3], '" } ], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function actionTokenUri(uint256 tokenId) internal view returns (string memory) {
        string[3] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: black; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="white" /><text x="10" y="20" class="base">';

        parts[1] = getAction(tokenId);

        parts[2] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', parts[1], '", "description": "Quests.", "attributes": [ { "trait_type": "Action Type", "value": "', parts[1], '" } ], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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