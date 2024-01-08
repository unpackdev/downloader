// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./base64.sol";

contract GreatLoot is ERC721Enumerable, ReentrancyGuard {
    string[] private weapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul",
        "Mace",
        "Club",
        "Katana",
        "Falchion",
        "Scimitar",
        "Long Sword",
        "Short Sword",
        "Ghost Wand",
        "Grave Wand",
        "Bone Wand",
        "Wand",
        "Grimoire",
        "Chronicle",
        "Tome",
        "Book"
    ];

    string[] private chestArmor = [
        "Divine Robe",
        "Silk Robe",
        "Linen Robe",
        "Robe",
        "Shirt",
        "Demon Husk",
        "Dragonskin Armor",
        "Studded Leather Armor",
        "Hard Leather Armor",
        "Leather Armor",
        "Holy Chestplate",
        "Ornate Chestplate",
        "Plate Mail",
        "Chain Mail",
        "Ring Mail"
    ];

    string[] private headArmor = [
        "Ancient Helm",
        "Ornate Helm",
        "Great Helm",
        "Full Helm",
        "Helm",
        "Demon Crown",
        "Dragon's Crown",
        "War Cap",
        "Leather Cap",
        "Cap",
        "Crown",
        "Divine Hood",
        "Silk Hood",
        "Linen Hood",
        "Hood"
    ];

    string[] private waistArmor = [
        "Ornate Belt",
        "War Belt",
        "Plated Belt",
        "Mesh Belt",
        "Heavy Belt",
        "Demonhide Belt",
        "Dragonskin Belt",
        "Studded Leather Belt",
        "Hard Leather Belt",
        "Leather Belt",
        "Brightsilk Sash",
        "Silk Sash",
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];

    string[] private footArmor = [
        "Holy Greaves",
        "Ornate Greaves",
        "Greaves",
        "Chain Boots",
        "Heavy Boots",
        "Demonhide Boots",
        "Dragonskin Boots",
        "Studded Leather Boots",
        "Hard Leather Boots",
        "Leather Boots",
        "Divine Slippers",
        "Silk Slippers",
        "Wool Shoes",
        "Linen Shoes",
        "Shoes"
    ];

    string[] private handArmor = [
        "Holy Gauntlets",
        "Ornate Gauntlets",
        "Gauntlets",
        "Chain Gloves",
        "Heavy Gloves",
        "Demon's Hands",
        "Dragonskin Gloves",
        "Studded Leather Gloves",
        "Hard Leather Gloves",
        "Leather Gloves",
        "Divine Gloves",
        "Silk Gloves",
        "Wool Gloves",
        "Linen Gloves",
        "Gloves"
    ];

    string[] private necklaces = ["Necklace", "Amulet", "Pendant"];

    string[] private rings = [
        "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
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
        "of the Twins"
    ];

    string[] private namePrefixes = [
        "Agony",
        "Apocalypse",
        "Armageddon",
        "Beast",
        "Behemoth",
        "Blight",
        "Blood",
        "Bramble",
        "Brimstone",
        "Brood",
        "Carrion",
        "Cataclysm",
        "Chimeric",
        "Corpse",
        "Corruption",
        "Damnation",
        "Death",
        "Demon",
        "Dire",
        "Dragon",
        "Dread",
        "Doom",
        "Dusk",
        "Eagle",
        "Empyrean",
        "Fate",
        "Foe",
        "Gale",
        "Ghoul",
        "Gloom",
        "Glyph",
        "Golem",
        "Grim",
        "Hate",
        "Havoc",
        "Honour",
        "Horror",
        "Hypnotic",
        "Kraken",
        "Loath",
        "Maelstrom",
        "Mind",
        "Miracle",
        "Morbid",
        "Oblivion",
        "Onslaught",
        "Pain",
        "Pandemonium",
        "Phoenix",
        "Plague",
        "Rage",
        "Rapture",
        "Rune",
        "Skull",
        "Sol",
        "Soul",
        "Sorrow",
        "Spirit",
        "Storm",
        "Tempest",
        "Torment",
        "Vengeance",
        "Victory",
        "Viper",
        "Vortex",
        "Woe",
        "Wrath",
        "Light's",
        "Shimmering"
    ];

    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
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

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }

    function getChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CHEST", chestArmor);
    }

    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", headArmor);
    }

    function getWaist(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WAIST", waistArmor);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOOT", footArmor);
    }

    function getHand(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HAND", handArmor);
    }

    function getNeck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NECK", necklaces);
    }

    function getRing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RING", rings);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(
                abi.encodePacked(output, " ", suffixes[rand % suffixes.length])
            );
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(
                    abi.encodePacked('"', name[0], " ", name[1], '" ', output)
                );
            } else {
                output = string(
                    abi.encodePacked(
                        '"',
                        name[0],
                        " ",
                        name[1],
                        '" ',
                        output,
                        " +1"
                    )
                );
            }
        }
        return output;
    }

    function getWeaponGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "WEAPON");
    }

    function getChestGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "CHEST");
    }

    function getHeadGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "HEAD");
    }

    function getWaistGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "WAIST");
    }

    function getFootGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "FOOT");
    }

    function getHandGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "HAND");
    }

    function getNeckGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "NECK");
    }

    function getRingGreatness(uint256 tokenId) public pure returns (uint256) {
        return getGreatness(tokenId, "RING");
    }

    function getGreatness(uint256 tokenId, string memory keyPrefix)
        internal
        pure
        returns (uint256)
    {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        return rand % 21;
    }

    function formatGreatness(uint256 greatness)
        internal
        pure
        returns (string memory)
    {
        if (greatness >= 10) {
            return toString(greatness);
        } else {
            return string(abi.encodePacked("0", toString(greatness)));
        }
    }

    function formatGreatnessAndPart(uint256 greatness, string memory part)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(formatGreatness(greatness), "   ", part));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory metadata)
    {
        string[19] memory parts;
        uint256 totalGreatness;
        {
            parts[
                0
            ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; white-space: pre; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

            uint256 weaponGreatness = getWeaponGreatness(tokenId);
            parts[1] = formatGreatnessAndPart(
                weaponGreatness,
                getWeapon(tokenId)
            );

            parts[2] = '</text><text x="10" y="40" class="base">';

            uint256 chestGreatness = getChestGreatness(tokenId);
            parts[3] = formatGreatnessAndPart(
                chestGreatness,
                getChest(tokenId)
            );

            parts[4] = '</text><text x="10" y="60" class="base">';

            uint256 headGreatness = getHeadGreatness(tokenId);
            parts[5] = formatGreatnessAndPart(headGreatness, getHead(tokenId));

            parts[6] = '</text><text x="10" y="80" class="base">';

            uint256 waistGreatness = getWaistGreatness(tokenId);
            parts[7] = formatGreatnessAndPart(
                waistGreatness,
                getWaist(tokenId)
            );

            parts[8] = '</text><text x="10" y="100" class="base">';

            uint256 footGreatness = getFootGreatness(tokenId);
            parts[9] = formatGreatnessAndPart(footGreatness, getFoot(tokenId));

            parts[10] = '</text><text x="10" y="120" class="base">';

            uint256 handGreatness = getHandGreatness(tokenId);
            parts[11] = formatGreatnessAndPart(handGreatness, getHand(tokenId));

            parts[12] = '</text><text x="10" y="140" class="base">';

            uint256 neckGreatness = getNeckGreatness(tokenId);
            parts[13] = formatGreatnessAndPart(neckGreatness, getNeck(tokenId));

            parts[14] = '</text><text x="10" y="160" class="base">';

            uint256 ringGreatness = getRingGreatness(tokenId);
            parts[15] = formatGreatnessAndPart(ringGreatness, getRing(tokenId));

            parts[16] = '</text><text x="10" y="335" class="base">';

            totalGreatness =
                weaponGreatness +
                chestGreatness +
                headGreatness +
                waistGreatness +
                footGreatness +
                handGreatness +
                neckGreatness +
                ringGreatness;
            parts[17] = formatGreatness(totalGreatness);

            parts[18] = "</text></svg>";
        }

        string memory image = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        image = string(
            abi.encodePacked(
                image,
                parts[7],
                parts[8],
                parts[9],
                parts[10],
                parts[11],
                parts[12]
            )
        );
        image = string(
            abi.encodePacked(
                image,
                parts[13],
                parts[14],
                parts[15],
                parts[16],
                parts[17],
                parts[18]
            )
        );

        // Name
        metadata = string(
            abi.encodePacked('{\n  "name": "Bag #', toString(tokenId), '",\n')
        );

        // Description
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "description": "Hidden deep in the original Loot contract is a \\"greatness\\" score between 0 and 20 for every item. Great Loot exposes these scores and lets you mint any bag with an ID higher than 100,000,000, in order to discover bags of untold greatness. Will a bag with perfect 160 greatness be found?",\n'
            )
        );

        // Image
        metadata = string(
            abi.encodePacked(
                metadata,
                '  "image": "',
                string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(bytes(image))
                    )
                ),
                '",\n'
            )
        );

        // Attributes
        metadata = string(abi.encodePacked(metadata, '  "attributes": [\n'));
        metadata = string(
            abi.encodePacked(
                metadata,
                '    {\n      "trait_type": "Greatness",\n      "value": "',
                toString(totalGreatness),
                '"\n',
                "    }\n"
            )
        );
        metadata = string(abi.encodePacked(metadata, "  ]\n}"));

        // base64 encode
        metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(metadata))
            )
        );
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 100_000_000, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
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

    constructor() ERC721("Great Loot", "gLOOT") {}
}
