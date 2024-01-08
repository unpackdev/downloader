/**
 *Submitted for verification at Etherscan.io on 2021-08-27
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Characters.sol";

contract Mounts is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public price = 10000000000000000; //0.01 ETH

    //Loot Contract
    address public characterAddress = 0x7403AC30DE7309a0bF019cdA8EeC034a5507cbB3;
    IERC721 public characterContract = IERC721(characterAddress);

    string[] private species = [
        "Horse",
        "Yak",
        "Boar",
        "Elk",
        "Lion",
        "Serpent",
        "Chocobo",
        "Tortoise",
        "Llama",
        "Elephant",
        "Gryphon",
        "Nightmare",
        "Wyvern",
        "Unicorn"
    ];

    string[] private class = [
        "Common",
        "Unique",
        "Elder",
        "Grand",
        "Massive",
        "Enchanted",
        "Fancy",
        "Mythical",
        "Legendary",
        "Demonic",
        "Blessed",
        "Uber"
    ];

    string[] private strength = [
        "Strength 1",
        "Strength 2",
        "Strength 3",
        "Strength 4",
        "Strength 5",
        "Strength 6",
        "Strength 7",
        "Strength 8",
        "Strength 9",
        "Strength 10"
    ];

    string[] private dexterity = [
        "Dexterity 1",
        "Dexterity 2",
        "Dexterity 3",
        "Dexterity 4",
        "Dexterity 5",
        "Dexterity 6",
        "Dexterity 7",
        "Dexterity 8",
        "Dexterity 9",
        "Dexterity 10"
    ];

    string[] private speed = [
        "Speed 1",
        "Speed 2",
        "Speed 3",
        "Speed 4",
        "Speed 5",
        "Speed 6",
        "Speed 7",
        "Speed 8",
        "Speed 9",
        "Speed 10"
    ];

    string[] private vitality = [
        "Vitality 1",
        "Vitality 2",
        "Vitality 3",
        "Vitality 4",
        "Vitality 5",
        "Vitality 6",
        "Vitality 7",
        "Vitality 8",
        "Vitality 9",
        "Vitality 10"
    ];

    string[] private luck = [
        "Luck 1",
        "Luck 2",
        "Luck 3",
        "Luck 4",
        "Luck 5",
        "Luck 6",
        "Luck 7",
        "Luck 8",
        "Luck 9",
        "Luck 10"
    ];

    string[] private flight = [
        "Flight 1",
        "Flight 2",
        "Flight 3",
        "Flight 4",
        "Flight 5",
        "Flight 6",
        "Flight 7",
        "Flight 8",
        "Flight 9",
        "Flight 10"
    ];

    string[] private move = [
        "Spit",
        "Bite",
        "Roar",
        "Charge",
        "Rage",
        "Slam",
        "Glare",
        "Impale",
        "Slash",
        "Trample",
        "Protect",
        "Thrash",
        "Smite"
    ];

    string[] private homeland = [
        "of the Eastern Mountains",
        "of the Southern Plains",
        "of the Western Dunes",
        "of the Northern Tundra",
        "of the Far Fountain",
        "of the Dark Forest",
        "of the Hallowed Spring",
        "of the Ethereal Mist",
        "of the Northwestern Sky",
        "of the Southeastern Woods",
        "of the Northeastern Sea",
        "of the Southwestern Islands",
        "of the Unholy Swamp",
        "of the Unwashed Bog",
        "of the Mystical Oasis",
        "of the Forsaken Hills",
        "of the Icy Wasteland",
        "of the Eternal Grassland",
        "of the Forgotten Steppe",
        "of the Boreal Valley",
        "of the Last Jungle",
        "of the White Sea",
        "of the Fallen Caves"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getSpecies(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SPECIES", species);
    }

    function getClass(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLASS", class);
    }

    function getStrength(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "STRENGTH", strength);
    }

    function getDexterity(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DEXTERITY", dexterity);
    }

    function getSpeed(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "SPEED", speed);
    }

    function getVitality(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "VITALITY", vitality);
    }

    function getLuck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LUCK", luck);
    }

    function getFlight(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FLIGHT", flight);
    }

    function getMove(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOVE", move);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );

        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256("SPECIES")) {
            string memory outputSpecies = getSpeciesWithRarity(rand);

            string[2] memory name;
            name[0] = getClass(tokenId);
            name[1] = homeland[rand % homeland.length];
            return string(
                abi.encodePacked(name[0], " ", outputSpecies, " ", name[1])
            );
        }

        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256("CLASS")) {
            return getClassWithRarity(rand);
        }

        return sourceArray[rand % sourceArray.length];
    }

    function getSpeciesWithRarity(uint256 rand) internal view returns (string memory) {
        // 14 species => 105 rarity slots
        uint256[105] memory speciesRarities;
        uint256 j = species.length;
        uint256 idx = 0;
        for (uint256 i = 0; i < species.length; i++) {
            for (uint256 k = 0; k < j; k++) {
                speciesRarities[idx] = i;
                idx++;
            }
            j--;
        }
        return species[speciesRarities[rand % speciesRarities.length]];
    }

    function getClassWithRarity(uint256 rand) internal view returns (string memory) {
        // 12 classes => 78 rarity slots
        uint256[78] memory classRarities;
        uint256 j = class.length;
        uint256 idx = 0;
        for (uint256 i = 0; i < class.length; i++) {
            for (uint256 k = 0; k < j; k++) {
                classRarities[idx] = i;
                idx++;
            }
            j--;
        }
        return class[classRarities[rand % classRarities.length]];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getSpecies(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getStrength(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getDexterity(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getSpeed(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getVitality(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getLuck(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getFlight(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getMove(tokenId);

        parts[16] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Mount #',
                        toString(tokenId),
                        '", "description": "Mounts are randomized generated and stored on chain. Images and other functionality are intentionally omitted for others to interpret. Feel free to use mounts in any way you want. Inspired and compatible with Loot (for Adventurers) and Characters (for Adventurers)", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function mint(uint256 mountId) public payable nonReentrant {
        require(
            characterContract.ownerOf(mountId) == msg.sender,
            "Not the owner of this character"
        );
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), mountId);
    }

    function multiMint(uint256[] memory mountIds) public payable nonReentrant {
        require(
            (price * mountIds.length) <= msg.value,
            "Ether value sent is not correct"
        );
        for (uint256 i = 0; i < mountIds.length; i++) {
            require(
                characterContract.ownerOf(mountIds[i]) == msg.sender,
                "Not the owner of this character"
            );
            _safeMint(msg.sender, mountIds[i]);
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(
            address(this).balance
        );
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

    constructor() ERC721("Mounts", "MOUNT") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
