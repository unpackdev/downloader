//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./NPassCore.sol";
import "./IN.sol";

/**
 * @title Dirty Business
 * @author Written by michaelshimeles; Developed by zhark
 */
contract DirtyBusiness is NPassCore {
    string[] private height = [
        "6'5",
        "5'3",
        "5'4",
        "5'5",
        "5'6",
        "5'7",
        "5'8",
        "5'9",
        "5'10",
        "5'11",
        "6'0",
        "6'1",
        "6'2",
        "6'3",
        "6'4"
    ];

    string[] private firstname = [
        "Mike",
        "Tony",
        "Tommy",
        "Al",
        "Carlo",
        "Clyde",
        "Johnny",
        "Sam",
        "Chad",
        "Frank",
        "Noah",
        "Pablo",
        "David",
        "Joseph",
        "Malique",
        "Dimitri",
        "Yapheth",
        "Finn",
        "Joshua",
        "Abraham",
        "Moses",
        "Sheldon",
        "Lando",
        "Lincoln",
        "Malcolm",
        "Niko",
        "Omar",
        "Ravi",
        "Santiago"
    ];

    string[] private nickname = [
        "Lucky",
        "8ball",
        "Scarface",
        "Enzo",
        "Mully",
        "Big Smoke",
        "Sweet",
        "The Bull",
        "Bando",
        "Bumpy",
        "Sunny",
        "Merky",
        "Houdini",
        "Durk",
        "Esco",
        "Dopey",
        "Drako",
        "Lil Baby",
        "Prince",
        "Blueface",
        "Benji",
        "Milli",
        "Nino",
        "Herbo",
        "Swervo",
        "Ras",
        "Sosa"
    ];

    string[] private lastname = [
        "Montana",
        "Malone",
        "Leone",
        "Woods",
        "Adonis",
        "Cipriani",
        "Santos",
        "Shelby",
        "Marino",
        "Castillo",
        "Buterin",
        "Johnson",
        "Gravano",
        "Solomon",
        "Lucas",
        "Lopez",
        "Hendrix",
        "Hunter",
        "Hayes",
        "Pierce",
        "Williams",
        "Jenkins",
        "Benjamin",
        "Petrov",
        "Soprano",
        "Brown",
        "Wayne",
        "D'Angelo",
        "Giuliani"
    ];

    string[] private bodybuild = [
        "Skinny",
        "Heavy",
        "Ample",
        "Stocky",
        "Bulky",
        "Athletic",
        "Swole",
        "Scrawny",
        "Burly",
        "Gangly",
        "Muscular",
        "Chubby",
        "Slim",
        "Toned"
    ];

    string[] private specialty = [
        "Martial Arts",
        "Shooting",
        "Money Management",
        "Business Expansion",
        "Networking",
        "Closer",
        "Leading",
        "Hacking",
        "Negotiation",
        "Driving",
        "Money Laundering",
        "Bootlegging",
        "Pickpocketing",
        "Identity Theft",
        "Bribery",
        "Carjacker",
        "Smuggling",
        "Counterfitting",
        "Looting (not for adventures)",
        "Lawyer",
        "Bookie",
        "Contraband"
    ];

    string[] private accessories = [
        "Designer Watch",
        "Watch",
        "Chain",
        "Grill",
        "Fedora",
        "Pocket Watch",
        "Earrings",
        "Cufflinks",
        "Ring",
        "Tobacco Pipe",
        "Glasses",
        "Brass Knuckles",
        "Gold Ring",
        "Designer Watch",
        "Diamond Chain"
    ];

    constructor(address _nContractAddress)
        NPassCore("DirtyBusiness", "DIRTY", IN(_nContractAddress), false, 8888, 0, 15000000000000000, 30000000000000000)
    {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getNSum(uint256 tokenId) internal view returns (uint256) {
        uint256 total = n.getFirst(tokenId) + n.getSecond(tokenId);
        total = total + n.getThird(tokenId);
        total = total + n.getFourth(tokenId);
        total = total + n.getFifth(tokenId);
        total = total + n.getSixth(tokenId);
        total = total + n.getSeventh(tokenId);
        total = total + n.getEight(tokenId);

        return total;
    }

    // N1
    function getName(uint256 tokenId) public view returns (string memory) {
        // First Name
        uint256 rand = random(string(abi.encodePacked(toString(getNSum(tokenId)), toString(tokenId))));
        string memory first = firstname[rand % firstname.length];

        // Nickname
        rand = random(string(abi.encodePacked(toString(n.getFirst(tokenId)), toString(tokenId))));
        string memory nick = nickname[rand % nickname.length];

        // Last Name
        rand = random(string(abi.encodePacked(toString(tokenId))));
        string memory last = lastname[rand % lastname.length];

        return string(abi.encodePacked(first, ' "', nick, '" ', last));
    }

    // N2
    function getHeight(uint256 tokenId) public view returns (string memory) {
        return height[n.getSecond(tokenId) % height.length];
    }

    // N3
    function getBodyBuild(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(toString(n.getThird(tokenId)), toString(tokenId))));
        return bodybuild[rand % bodybuild.length];
    }

    // N4
    function getMentalFortitude(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(toString(n.getFourth(tokenId)), toString(tokenId))));
        uint256 fortitude = (rand % 50) + 51;
        if (fortitude > 94) {
            return "Mental Fortitude: Very High";
        } else {
            return string(abi.encodePacked("Mental Fortitude: ", toString(fortitude)));
        }
    }

    // N5
    function getPersonality(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(toString(n.getFifth(tokenId)), toString(tokenId))));
        uint256 personality = rand % 1000;
        if (personality < 164) return "ISTJ - The Logistician";
        else if (personality < 276) return "ESTJ - The Executive";
        else if (personality < 361) return "ISTP - The Virtuoso";
        else if (personality < 442) return "ISFJ - The Defender";
        else if (personality < 518) return "ISFP - The Adventurer";
        else if (personality < 593) return "ESFJ - The Consul";
        else if (personality < 662) return "ESFP - The Entertainer";
        else if (personality < 726) return "ENFP - The Campaigner";
        else if (personality < 782) return "ESTP - The Entrepreneur";
        else if (personality < 830) return "INTP - The Logician";
        else if (personality < 871) return "INFP - The Mediator";
        else if (personality < 911) return "ENTP - The Debater";
        else if (personality < 944) return "INTJ - The Architect";
        else if (personality < 971) return "ENTJ - The Commander";
        else if (personality < 987) return "ENFJ - The Protagonist";
        else return "INFJ - The Advocate";
    }

    // N6
    function getAimAccuracy(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(toString(n.getSixth(tokenId)), toString(tokenId))));
        uint256 accuracy = (rand % 50) + 51;
        if (accuracy > 94) {
            return "Aim Accuracy: Sharpshooter";
        } else {
            return string(abi.encodePacked("Aim Accuracy: ", toString(accuracy)));
        }
    }

    // N7
    function getSpecialty(uint256 tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(toString(n.getSeventh(tokenId)), toString(tokenId))));
        return specialty[rand % specialty.length];
    }

    // N8
    function getItem(uint256 tokenId) public view returns (string memory) {
        return accessories[n.getEight(tokenId) % accessories.length];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; } .name {text-decoration: underline;}</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base name">';

        parts[1] = getName(tokenId); // N1

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getHeight(tokenId); // N2

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getBodyBuild(tokenId); // N3

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getMentalFortitude(tokenId); // N4

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getPersonality(tokenId); // N5

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getAimAccuracy(tokenId); // N6

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getSpecialty(tokenId); // N7

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getItem(tokenId); // N8

        parts[16] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
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
                        '{"name": "Dirty Business Character #',
                        toString(tokenId),
                        '", "description": "Welcome to Dirty Business, a virtual world of crime. There is only one choice. Get rich or die trying. Start a gang, equip them with weapons, purchase land, create profitable businesses, clean your money, and rise to the top of the food chain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
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
