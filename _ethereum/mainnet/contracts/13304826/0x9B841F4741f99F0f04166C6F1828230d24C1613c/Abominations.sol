// contracts/Abominations.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Abominations is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant LIMIT_PUBLIC = 3112;
    uint256 public constant LIMIT_OWNER = 100;
    uint256 public constant MAX = LIMIT_PUBLIC + LIMIT_OWNER;

    bool public isActive = false;

    uint256 public totalPublicSupply;
    uint256 public totalOwnerSupply;

    /*
     * Text slots are not strictly mapped to different body parts. The
     * first slot has a high chance to be a body, the second slot a
     * high chance to be a head, and the rest are most likely to be
     * other types of body parts. Some creatures may be a mass of
     * limbs with no discernible body; some may have several heads or
     * sets of legs, or none at all. Many may be deemed failures.
     */

    /**
     * @dev The arrays below have repeating elements so that the random
     * selection will be weighted. Originally this was achieved by
     * assigning each element a numerical weight and storing both in
     * a struct, but the logic required for that implementation made
     * the contract size too big.
     */

    string[] private slot1 = [
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "body",
        "head",
        "bone",
        "eyes",
        "other"
    ];

    string[] private slot2 = [
        "head",
        "head",
        "head",
        "head",
        "head",
        "head",
        "head",
        "head",
        "head",
        "head",
        "bone",
        "legs",
        "eyes",
        "other"
    ];

    string[] private slotOther = [
        "head",
        "bone",
        "bone",
        "legs",
        "legs",
        "legs",
        "legs",
        "legs",
        "eyes",
        "eyes",
        "other",
        "other",
        "other",
        "other",
        "other",
        "other",
        "other"
    ];

    string[] private bodies = [
        "snake body",
        "spider body",
        "gelatinous body",
        "slug body",
        "boar body",
        "boar body",
        "centipede body",
        "obese body",
        "obese body",
        "obese body",
        "obese body",
        "obese body",
        "muscular body",
        "muscular body",
        "muscular body",
        "muscular body",
        "muscular body",
        "crustacean body",
        "crustacean body",
        "crustacean body",
        "crustacean body",
        "behemoth body",
        "behemoth body",
        "behemoth body",
        "toad body",
        "toad body",
        "lean body",
        "lean body",
        "lean body",
        "lean body",
        "eel body",
        "mass of tendrils",
        "mass of bodies",
        "emaciated body",
        "emaciated body",
        "emaciated body",
        "emaciated body",
        "emaciated body",
        "fish-humanoid body",
        "fish-humanoid body",
        "fish-humanoid body",
        "fish-humanoid body",
        "reptilian humanoid body",
        "reptilian humanoid body",
        "reptilian humanoid body",
        "reptilian humanoid body",
        "wolf-humanoid body",
        "wolf-humanoid body",
        "wolf-humanoid body",
        "wolf-humanoid body",
        "amorphous blob",
        "amorphous blob"
    ];

    string[] private modifiers = [
        "crystalline",
        "mushroom-infested",
        "mushroom-infested",
        "sickly",
        "sickly",
        "sickly",
        "sickly",
        "tumored",
        "tumored",
        "tumored",
        "tumored",
        "pustuled",
        "pustuled",
        "pustuled",
        "pustuled",
        "albino",
        "albino",
        "albino",
        "albino",
        "slimy",
        "slimy",
        "slimy",
        "slimy",
        "many-eyed",
        "many-eyed",
        "many-eyed",
        "many-eyed",
        "infested",
        "infested",
        "infested",
        "infested",
        "spiny",
        "spiny",
        "spiny",
        "spiny",
        "stitched",
        "stitched",
        "stitched",
        "stitched",
        "scorched",
        "scorched",
        "scorched",
        "scorched",
        "decayed",
        "decayed",
        "decayed",
        "decayed",
        "skeletal",
        "skeletal",
        "skeletal",
        "elongated",
        "elongated",
        "elongated",
        "elongated",
        "scaly",
        "scaly",
        "scaly",
        "scaly",
        "feathered",
        "feathered",
        "feathered",
        "feathered",
        "hairy",
        "hairy",
        "hairy",
        "hairy",
        "furred",
        "furred",
        "furred",
        "furred",
        "putrefied",
        "putrefied",
        "putrefied",
        "putrefied",
        "withered",
        "withered",
        "withered",
        "withered",
        "molten",
        "waxy",
        "waxy",
        "waxy",
        "waxy",
        "veiny",
        "veiny",
        "veiny",
        "veiny",
        "bloody",
        "bloody",
        "bloody",
        "bloody",
        "bandaged",
        "bandaged",
        "bandaged",
        "barnacled",
        "barnacled"
    ];

    string[] private heads = [
        "wolf head",
        "wolf head",
        "wolf head",
        "wolf head",
        "goat head",
        "goat head",
        "goat head",
        "goat head",
        "shark head",
        "shark head",
        "shark head",
        "shark head",
        "spider head",
        "spider head",
        "spider head",
        "spider head",
        "crow head",
        "crow head",
        "crow head",
        "crow head",
        "horse head",
        "horse head",
        "horse head",
        "horse head",
        "behemoth head",
        "behemoth head",
        "behemoth head",
        "behemoth head",
        "bat head",
        "bat head",
        "bat head",
        "bat head",
        "moth head",
        "moth head",
        "moth head",
        "moth head",
        "snake head",
        "snake head",
        "snake head",
        "snake head",
        "lion head",
        "lion head",
        "lion head",
        "lion head",
        "mantis head",
        "mantis head",
        "mantis head",
        "mantis head",
        "werewolf head",
        "werewolf head",
        "werewolf head",
        "vampire head",
        "vampire head",
        "vampire head",
        "bull head",
        "bull head",
        "bull head",
        "bull head",
        "bear head",
        "bear head",
        "bear head",
        "bear head",
        "boar head",
        "boar head",
        "boar head",
        "boar head",
        "crocodile head",
        "crocodile head",
        "crocodile head",
        "crocodile head",
        "squid head",
        "squid head",
        "squid head",
        "squid head",
        "angler fish head",
        "star-nosed mole head",
        "toad head",
        "toad head",
        "toad head",
        "toad head",
        "rat head",
        "rat head",
        "rat head",
        "rat head",
        "ape head",
        "ape head",
        "ape head",
        "ape head",
        "human head",
        "human head",
        "human head",
        "human head",
        "piranha head",
        "piranha head",
        "piranha head",
        "piranha head",
        "hyena head",
        "hyena head",
        "hyena head",
        "vulture head",
        "vulture head",
        "owl head"
    ];

    string[] private headModifiers = [
        "shark-toothed",
        "wolf-toothed",
        "many-eyed",
        "three-eyed",
        "fish-eyed",
        "cyclopean",
        "bear-toothed",
        "horse-toothed",
        "saber-toothed",
        "tentacle-mouthed",
        "human-toothed"
    ];

    string[] private bones = [
        "elephant tusks",
        "boar tusks",
        "goat horns",
        "elk antlers",
        "deer antlers",
        "bull horns"
    ];

    string[] private boneModifiers = [
        "crystalline",
        "mushroom-infested",
        "mushroom-infested",
        "mushroom-infested",
        "mushroom-infested",
        "mushroom-infested",
        "elongated",
        "elongated",
        "slimy",
        "slimy",
        "slimy",
        "slimy",
        "slimy",
        "molten",
        "scorched",
        "scorched",
        "scorched",
        "scorched",
        "scorched",
        "bloody",
        "bloody",
        "bloody",
        "bloody",
        "many-eyed"
    ];

    string[] private legs = [
        "human legs",
        "spider legs",
        "boar legs",
        "centipede legs",
        "werewolf legs",
        "iguana legs",
        "gecko legs",
        "salamander legs",
        "goat legs",
        "komodo dragon legs",
        "bear legs",
        "crocodile legs",
        "lobster legs",
        "mantis legs",
        "horse legs",
        "toad legs",
        "wolf legs"
    ];

    string[] private eyes = [
        "reptilian eyes",
        "alligator eyes",
        "snake eyes",
        "squid eyes",
        "octopus eyes",
        "fish eyes",
        "goat eyes",
        "crab eyes",
        "insect eyes",
        "glowing red eyes",
        "glowing green eyes",
        "spider eyes",
        "lemur eyes",
        "mantis shrimp eyes",
        "human eyes",
        "giant eye"
    ];

    string[] private otherParts = [
        "human arm",
        "monkey paw",
        "monkey tail",
        "shark fin",
        "bat wings",
        "muscular hydrostat",
        "tentacle",
        "tentacles",
        "starfish",
        "cuttlefish tentacles",
        "slug tentacle",
        "octopus tentacle",
        "squid tentacle",
        "crow wings",
        "lobster claw",
        "scorpion tail",
        "werewolf arms",
        "mantis claws",
        "bear arm",
        "crocodile tail",
        "webbed hands",
        "sloth arm",
        "moth wings",
        "exposed brain",
        "mole hands",
        "eye stalks",
        "eye stalk",
        "gorilla arms",
        "reptilian humanoid arms",
        "fish-humanoid arms",
        "vulture claws"
    ];

    constructor() ERC721("Abominations (for Necromancers)", "ABOM") {}

    function random(string memory seed, uint256 max)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(seed))) % max;
    }

    function getByType(uint256 tokenId, uint256 slotNo)
        public
        view
        returns (string memory)
    {
        string memory seed = string(
            abi.encodePacked(tokenId.toString(), slotNo.toString())
        );

        string[] memory bodyPartTypes;
        if (slotNo == 1) {
            bodyPartTypes = slot1;
        } else if (slotNo == 2) {
            bodyPartTypes = slot2;
        } else {
            bodyPartTypes = slotOther;
        }

        bytes32 chosenTypeHash = keccak256(
            bytes(bodyPartTypes[random(seed, bodyPartTypes.length)])
        );
        string memory mod = modifiers[random(seed, modifiers.length)];
        uint256 roll = random(seed, 20);

        /**
         * BODY
         */
        if (chosenTypeHash == keccak256(bytes("body"))) {
            string memory body = bodies[random(seed, bodies.length)];
            if (roll <= 10) {
                /** 50% chance for just body */
                return body;
            } else if (roll <= 15) {
                /** 25% chance for just modifier */
                return string(abi.encodePacked(mod, " body"));
            } else {
                /** 25% chance for modifier + body */
                return string(abi.encodePacked(mod, " ", body));
            }
        }
        /**
         * HEAD
         */
        else if (chosenTypeHash == keccak256(bytes("head"))) {
            string memory head = heads[random(seed, heads.length)];
            if (roll <= 7) {
                /** Chance for modifier + head */
                return
                    string(
                        abi.encodePacked(
                            headModifiers[random(seed, headModifiers.length)],
                            " ",
                            head
                        )
                    );
            } else {
                /** Chance for just head */
                return head;
            }
        }
        /**
         * BONE PART
         */
        else if (chosenTypeHash == keccak256(bytes("bone"))) {
            string memory bone = bones[random(seed, bones.length)];
            if (roll <= 7) {
                /** Chance for modifier + bone part */
                return
                    string(
                        abi.encodePacked(
                            boneModifiers[random(seed, boneModifiers.length)],
                            " ",
                            bone
                        )
                    );
            } else {
                /** Chance for just bone part */
                return bone;
            }
        }
        /**
         * LEGS
         */
        else if (chosenTypeHash == keccak256(bytes("legs"))) {
            string memory leg = legs[random(seed, legs.length)];
            if (roll <= 7) {
                /** Chance for modifier + legs */
                return string(abi.encodePacked(mod, " ", leg));
            } else {
                /** Chance for just legs */
                return leg;
            }
        }
        /**
         * EYES
         */
        else if (chosenTypeHash == keccak256(bytes("eyes"))) {
            return eyes[random(seed, eyes.length)];
        }
        /**
         * OTHER PARTS
         */
        else {
            string memory otherPart = otherParts[
                random(seed, otherParts.length)
            ];
            /** Chance for modifier + part */
            if (roll <= 7) {
                return string(abi.encodePacked(mod, " ", otherPart));
            } else {
                /** Chance for just part */
                return otherPart;
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[15] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 350 350"><style>rect { fill: black; } text { fill: #fff; font-size: 14px; font-family: serif; }</style><rect width="100%" height="100%"/><text x="25" y="30">';

        parts[1] = getByType(tokenId, 1);

        parts[2] = '</text><text x="25" y="50">';

        parts[3] = getByType(tokenId, 2);

        parts[4] = '</text><text x="25" y="70">';

        parts[5] = getByType(tokenId, 3);

        parts[6] = '</text><text x="25" y="90">';

        parts[7] = getByType(tokenId, 4);

        parts[8] = '</text><text x="25" y="110">';

        parts[9] = getByType(tokenId, 5);

        parts[10] = '</text><text x="25" y="130">';

        parts[11] = getByType(tokenId, 6);

        parts[12] = '</text><text x="25" y="150">';

        parts[13] = getByType(tokenId, 7);

        parts[14] = "</text></svg>";

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
                parts[8],
                parts[9],
                parts[10],
                parts[11]
            )
        );
        output = string(
            abi.encodePacked(output, parts[12], parts[13], parts[14])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Abomination #',
                        tokenId.toString(),
                        '", "description": "Randomly generated abominations with a mysterious origin, immortalized on-chain.", "image": "data:image/svg+xml;base64,',
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

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function mint() external nonReentrant {
        require(isActive, "Contract not active");
        require(totalSupply() < MAX, "No tokens left");
        require(totalPublicSupply < LIMIT_PUBLIC, "No public tokens left");

        uint256 newItemId = totalPublicSupply + 1;
        totalPublicSupply += 1;
        _safeMint(msg.sender, newItemId);
    }

    function ownerMint(uint256 numberOfTokens) external nonReentrant onlyOwner {
        require(isActive, "Contract not active");
        require(totalSupply() < MAX, "No tokens left");
        require(totalOwnerSupply < LIMIT_OWNER, "No owner tokens left");
        require(
            totalOwnerSupply + numberOfTokens <= LIMIT_OWNER,
            "Too many tokens requested"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 newItemId = LIMIT_PUBLIC + totalOwnerSupply + 1;
            totalOwnerSupply += 1;
            _safeMint(msg.sender, newItemId);
        }
    }
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
