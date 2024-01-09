// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UintUtils.sol";
import "./base64.sol";
import "./ChonkyGenomeLib.sol";
import "./ChonkyAttributes.sol";
import "./ChonkySet.sol";

import "./IChonkyMetadata.sol";
import "./IChonkySet.sol";

contract ChonkyMetadata is IChonkyMetadata {
    using UintUtils for uint256;

    function buildTokenURI(
        uint256 id,
        uint256 genomeId,
        uint256 genome,
        string memory CID,
        address chonkyAttributes,
        address chonkySet
    ) public pure returns (string memory) {
        string
            memory description = "A collection of 7777 mischievous Chonky's ready to wreak havoc on the ETH blockchain.";
        string memory attributes = _buildAttributes(
            genome,
            chonkyAttributes,
            chonkySet
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"image":"ipfs://',
                                CID,
                                "/",
                                _buildPaddedID(genomeId),
                                '.png",',
                                '"description":"',
                                description,
                                '",',
                                '"name":"Chonky',
                                "'s #",
                                _buildPaddedID(id),
                                '",',
                                attributes,
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function _buildPaddedID(uint256 id) internal pure returns (string memory) {
        if (id == 0) return "0000";
        if (id < 10) return string(abi.encodePacked("000", id.toString()));
        if (id < 100) return string(abi.encodePacked("00", id.toString()));
        if (id < 1000) return string(abi.encodePacked("0", id.toString()));

        return id.toString();
    }

    ////

    function _getBGBase(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Aqua";
        if (id == 2) return "Black";
        if (id == 3) return "Brown";
        if (id == 4) return "Dark Purple";
        if (id == 5) return "Dark Red";
        if (id == 6) return "Gold";
        if (id == 7) return "Green";
        if (id == 8) return "Green Apple";
        if (id == 9) return "Grey";
        if (id == 10) return "Ice Blue";
        if (id == 11) return "Kaki";
        if (id == 12) return "Orange";
        if (id == 13) return "Pink";
        if (id == 14) return "Purple";
        if (id == 15) return "Rainbow";
        if (id == 16) return "Red";
        if (id == 17) return "Sky Blue";
        if (id == 18) return "Yellow";

        return "";
    }

    function _getBGRare(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "HamHam";
        if (id == 2) return "Japan";
        if (id == 3) return "Skulls";
        if (id == 4) return "Stars";

        return "";
    }

    function _getWings(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Angel";
        if (id == 2) return "Bat";
        if (id == 3) return "Bee";
        if (id == 4) return "Crystal";
        if (id == 5) return "Devil";
        if (id == 6) return "Dragon";
        if (id == 7) return "Fairy";
        if (id == 8) return "Plant";
        if (id == 9) return "Robot";

        return "";
    }

    function _getSkin(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Almond";
        if (id == 2) return "Aqua";
        if (id == 3) return "Blue";
        if (id == 4) return "Brown";
        if (id == 5) return "Cream";
        if (id == 6) return "Dark";
        if (id == 7) return "Dark Blue";
        if (id == 8) return "Gold";
        if (id == 9) return "Green";
        if (id == 10) return "Grey";
        if (id == 11) return "Ice";
        if (id == 12) return "Indigo";
        if (id == 13) return "Light Brown";
        if (id == 14) return "Light Purple";
        if (id == 15) return "Neon Blue";
        if (id == 16) return "Orange";
        if (id == 17) return "Pink";
        if (id == 18) return "Purple";
        if (id == 19) return "Rose White";
        if (id == 20) return "Salmon";
        if (id == 21) return "Skye Blue";
        if (id == 22) return "Special Red";
        if (id == 23) return "White";
        if (id == 24) return "Yellow";

        return "";
    }

    function _getPattern(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "3 Dots";
        if (id == 2) return "3 Triangles";
        if (id == 3) return "Corner";
        if (id == 4) return "Dalmatian";
        if (id == 5) return "Half";
        if (id == 6) return "Tiger Stripes";
        if (id == 7) return "Triangle";
        if (id == 8) return "White Reversed V";
        if (id == 9) return "Zombie";

        return "";
    }

    function _getPaint(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Beard";
        if (id == 2) return "Board";
        if (id == 3) return "Earrings";
        if (id == 4) return "Face Tattoo";
        if (id == 5) return "Happy Cheeks";
        if (id == 6) return "Pink Star";
        if (id == 7) return "Purple Star";
        if (id == 8) return "Scar";

        return "";
    }

    function _getBody(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Retro Shirt";
        if (id == 2) return "Angel Wings";
        if (id == 3) return "Aqua Monster";
        if (id == 4) return "Astronaut";
        if (id == 5) return "Bag";
        if (id == 6) return "Baron Samedi";
        if (id == 7) return "Bee";
        if (id == 8) return "Black Samurai";
        if (id == 9) return "Black Wizard";
        if (id == 10) return "Blue Football";
        if (id == 11) return "Blue Parka";
        if (id == 12) return "Blue Kimono";
        if (id == 13) return "Blue Hoodie";
        if (id == 14) return "Blue Wizard";
        if (id == 15) return "Jester";
        if (id == 16) return "Bubble Tea";
        if (id == 17) return "Captain";
        if (id == 18) return "Caveman";
        if (id == 19) return "Chef";
        if (id == 20) return "Chinese Shirt";
        if (id == 21) return "Cloth Monster";
        if (id == 22) return "Color Shirt";
        if (id == 23) return "Cowboy Shirt";
        if (id == 24) return "Cyber Assassin";
        if (id == 25) return "Devil Wings";
        if (id == 26) return "Scuba";
        if (id == 27) return "Doreamon";
        if (id == 28) return "Dracula";
        if (id == 29) return "Gold Chain";
        if (id == 30) return "Green Cyber";
        if (id == 31) return "Green Parka";
        if (id == 32) return "Green Kimono";
        if (id == 33) return "Green Hoodie";
        if (id == 34) return "Hamsterdam Shirt";
        if (id == 35) return "Hazard";
        if (id == 36) return "Hiding Hamster";
        if (id == 37) return "Pink Punk Girl";
        if (id == 38) return "Japanese Worker";
        if (id == 39) return "King";
        if (id == 40) return "Leather Jacket";
        if (id == 41) return "Leaves";
        if (id == 42) return "Lobster";
        if (id == 43) return "Luffy";
        if (id == 44) return "Magenta Cyber";
        if (id == 45) return "Sailor";
        if (id == 46) return "Mario Pipe";
        if (id == 47) return "Mommy";
        if (id == 48) return "Ninja";
        if (id == 49) return "Old Grandma";
        if (id == 50) return "Orange Jumpsuit";
        if (id == 51) return "Chili";
        if (id == 52) return "Chili Fire";
        if (id == 53) return "Pharaoh";
        if (id == 54) return "Pink Football";
        if (id == 55) return "Pink Ruff";
        if (id == 56) return "Pink Jumpsuit";
        if (id == 57) return "Pink Kimono";
        if (id == 58) return "Pink Polo";
        if (id == 59) return "Pirate";
        if (id == 60) return "Plague Doctor";
        if (id == 61) return "Poncho";
        if (id == 62) return "Purple Cyber";
        if (id == 63) return "Purple Polo";
        if (id == 64) return "Mystery Hoodie";
        if (id == 65) return "Rainbow Snake";
        if (id == 66) return "Red Ruff";
        if (id == 67) return "Red Punk Girl";
        if (id == 68) return "Red Samurai";
        if (id == 69) return "Referee";
        if (id == 70) return "Robotbod";
        if (id == 71) return "Robot Cyber";
        if (id == 72) return "Rocker";
        if (id == 73) return "Roman Legionary";
        if (id == 74) return "Safari";
        if (id == 75) return "Scout";
        if (id == 76) return "Sherlock";
        if (id == 77) return "Shirt";
        if (id == 78) return "Snow Coat";
        if (id == 79) return "Sparta";
        if (id == 80) return "Steampunk";
        if (id == 81) return "Suit";
        if (id == 82) return "Tie";
        if (id == 83) return "Tire";
        if (id == 84) return "Toga";
        if (id == 85) return "Tron";
        if (id == 86) return "Valkyrie";
        if (id == 87) return "Viking";
        if (id == 88) return "Wereham";
        if (id == 89) return "White Cloak";
        if (id == 90) return "Yellow Jumpsuit";
        if (id == 91) return "Zombie";

        return "";
    }

    function _getMouth(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Black Gas Mask Ninja";
        if (id == 2) return "Black Ninja Mask";
        if (id == 3) return "Shocked";
        if (id == 4) return "Creepy";
        if (id == 5) return "=D";
        if (id == 6) return "Drawing";
        if (id == 7) return "Duck";
        if (id == 8) return "Elegant Moustache";
        if (id == 9) return "Fire";
        if (id == 10) return "Gold Teeth";
        if (id == 11) return "Grey Futuristic Gas Mask";
        if (id == 12) return "Happy Open";
        if (id == 13) return "Goatee";
        if (id == 14) return "Honey";
        if (id == 15) return "Jack-O-Lantern";
        if (id == 16) return "Lipstick";
        if (id == 17) return "Little Moustache";
        if (id == 18) return "Luffy Smile";
        if (id == 19) return "Sanitary Mask";
        if (id == 20) return "Robot Mask";
        if (id == 21) return "Mega Happy";
        if (id == 22) return "Mega Tongue Out";
        if (id == 23) return "Meh";
        if (id == 24) return "Mexican Moustache";
        if (id == 25) return "Monster";
        if (id == 26) return "Moustache";
        if (id == 27) return "Drunk";
        if (id == 28) return "Fake Moustache";
        if (id == 29) return "Full";
        if (id == 30) return "Piece";
        if (id == 31) return "Stretch";
        if (id == 32) return "Ninja";
        if (id == 33) return "Normal";
        if (id == 34) return "Ohhhh";
        if (id == 35) return "Chili";
        if (id == 36) return "Purple Futuristic Gas Mask";
        if (id == 37) return "Red Gas Mask Ninja";
        if (id == 38) return "Red Ninja Mask";
        if (id == 39) return "Robot Mouth";
        if (id == 40) return "Scream";
        if (id == 41) return "Cigarette";
        if (id == 42) return "Smoking Pipe";
        if (id == 43) return "Square";
        if (id == 44) return "Steampunk";
        if (id == 45) return "Stitch";
        if (id == 46) return "Super Sad";
        if (id == 47) return "Thick Moustache";
        if (id == 48) return "Tongue";
        if (id == 49) return "Tongue Out";
        if (id == 50) return "Triangle";
        if (id == 51) return "Vampire";
        if (id == 52) return "Wave";
        if (id == 53) return "What";
        if (id == 54) return "YKWIM";

        return "";
    }

    function _getEyes(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "^_^";
        if (id == 2) return ">_<";
        if (id == 3) return "=_=";
        if (id == 4) return "3D";
        if (id == 5) return "Angry";
        if (id == 6) return "Button";
        if (id == 7) return "Confused";
        if (id == 8) return "Crazy";
        if (id == 9) return "Cute";
        if (id == 10) return "Cyber Glasses";
        if (id == 11) return "Cyclops";
        if (id == 12) return "Depressed";
        if (id == 13) return "Determined";
        if (id == 14) return "Diving Mask";
        if (id == 15) return "Drawing";
        if (id == 16) return "Morty";
        if (id == 17) return "Eyepatch";
        if (id == 18) return "Fake Moustache";
        if (id == 19) return "Flower Glasses";
        if (id == 20) return "Frozen";
        if (id == 21) return "Furious";
        if (id == 22) return "Gengar";
        if (id == 23) return "Glasses Depressed";
        if (id == 24) return "Goku";
        if (id == 25) return "Green Underwear";
        if (id == 26) return "Hippie";
        if (id == 27) return "Kawaii";
        if (id == 28) return "Line Glasses";
        if (id == 29) return "Looking Up";
        if (id == 30) return "Looking Up Happy";
        if (id == 31) return "Mini Sunglasses";
        if (id == 32) return "Monocle";
        if (id == 33) return "Monster";
        if (id == 34) return "Ninja";
        if (id == 35) return "Normal";
        if (id == 36) return "Not Impressed";
        if (id == 37) return "o_o";
        if (id == 38) return "Orange Underwear";
        if (id == 39) return "Pink Star Sunglasses";
        if (id == 40) return "Pissed";
        if (id == 41) return "Pixel Glasses";
        if (id == 42) return "Plague Doctor Mask";
        if (id == 43) return "Proud";
        if (id == 44) return "Raccoon";
        if (id == 45) return "Red Dot";
        if (id == 46) return "Red Star Sunglasses";
        if (id == 47) return "Robot Eyes";
        if (id == 48) return "Scared Eyes";
        if (id == 49) return "Snorkel";
        if (id == 50) return "Serious Japan";
        if (id == 51) return "Seriously";
        if (id == 52) return "Star";
        if (id == 53) return "Steampunk Glasses";
        if (id == 54) return "Sunglasses";
        if (id == 55) return "Sunglasses Triangle";
        if (id == 56) return "Surprised";
        if (id == 57) return "Thick Eyebrows";
        if (id == 58) return "Troubled";
        if (id == 59) return "UniBrow";
        if (id == 60) return "Weird";
        if (id == 61) return "X_X";

        return "";
    }

    function _getLostKing(uint256 _id) internal pure returns (string memory) {
        if (_id == 1) return "The Glitch King";
        if (_id == 2) return "The Gummy King";
        if (_id == 3) return "King Diamond";
        if (_id == 4) return "The King of Gold";
        if (_id == 5) return "King Unicorn";
        if (_id == 6) return "The Last King";
        if (_id == 7) return "The Monkey King";

        return "";
    }

    function _getHonorary(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Crunchies";
        if (id == 2) return "Chuckle";
        if (id == 3) return "ChainLinkGod";
        if (id == 4) return "Crypt0n1c";
        if (id == 5) return "Bigdham";
        if (id == 6) return "Cyclopeape";
        if (id == 7) return "Elmo";
        if (id == 8) return "Caustik";
        if (id == 9) return "Churby";
        if (id == 10) return "Chonko";
        if (id == 11) return "Hamham";
        if (id == 12) return "Icebergy";
        if (id == 13) return "IronHam";
        if (id == 14) return "RatWell";
        if (id == 15) return "VangogHam";
        if (id == 16) return "Boneham";

        return "";
    }

    function _getHat(uint256 id) internal pure returns (string memory) {
        if (id == 1) return "Retro";
        if (id == 2) return "Aqua Monster";
        if (id == 3) return "Astronaut";
        if (id == 4) return "Baby Hamster";
        if (id == 5) return "Baron Samedi";
        if (id == 6) return "Bear Skin";
        if (id == 7) return "Bee";
        if (id == 8) return "Beanie";
        if (id == 9) return "Beret";
        if (id == 10) return "Biker Helmet";
        if (id == 11) return "Black Afro";
        if (id == 12) return "Black Hair JB";
        if (id == 13) return "Black Kabuki Mask";
        if (id == 14) return "Black Kabuto";
        if (id == 15) return "Black Magician";
        if (id == 16) return "Black Toupee";
        if (id == 17) return "Bolts";
        if (id == 18) return "Jester";
        if (id == 19) return "Brain";
        if (id == 20) return "Brown Hair JB";
        if (id == 21) return "Candle";
        if (id == 22) return "Captain";
        if (id == 23) return "Cheese";
        if (id == 24) return "Chef";
        if (id == 25) return "Cloth Monster";
        if (id == 26) return "Cone";
        if (id == 27) return "Cowboy";
        if (id == 28) return "Crown";
        if (id == 29) return "Devil Horns";
        if (id == 30) return "Dracula";
        if (id == 31) return "Duck";
        if (id == 32) return "Elvis";
        if (id == 33) return "Fish";
        if (id == 34) return "Fan";
        if (id == 35) return "Fire";
        if (id == 36) return "Fluffy Beanie";
        if (id == 37) return "Pigskin";
        if (id == 38) return "Futuristic Crown";
        if (id == 39) return "Golden Horns";
        if (id == 40) return "Green Fire";
        if (id == 41) return "Green Knot";
        if (id == 42) return "Green Punk";
        if (id == 43) return "Green Visor";
        if (id == 44) return "Halo";
        if (id == 45) return "Headband";
        if (id == 46) return "Ice";
        if (id == 47) return "Injury";
        if (id == 48) return "Kabuto";
        if (id == 49) return "Leaf";
        if (id == 50) return "Lion Head";
        if (id == 51) return "Long Hair Front";
        if (id == 52) return "Magician";
        if (id == 53) return "Mario Flower";
        if (id == 54) return "Mini Cap";
        if (id == 55) return "Ninja Band";
        if (id == 56) return "Mushroom";
        if (id == 57) return "Ninja";
        if (id == 58) return "Noodle Cup";
        if (id == 59) return "Octopus";
        if (id == 60) return "Old Lady";
        if (id == 61) return "Pancakes";
        if (id == 62) return "Paper Hat";
        if (id == 63) return "Pharaoh";
        if (id == 64) return "Pink Exploding Hair";
        if (id == 65) return "Pink Hair Girl";
        if (id == 66) return "Pink Mini Cap";
        if (id == 67) return "Pink Punk";
        if (id == 68) return "Pink Visor";
        if (id == 69) return "Pirate";
        if (id == 70) return "Plague Doctor";
        if (id == 71) return "Plant";
        if (id == 72) return "Punk Helmet";
        if (id == 73) return "Purple Mini Cap";
        if (id == 74) return "Purple Top Hat";
        if (id == 75) return "Rainbow Afro";
        if (id == 76) return "Rainbow Ice Cream";
        if (id == 77) return "Red Black Hair Girl";
        if (id == 78) return "Red Knot";
        if (id == 79) return "Red Punk";
        if (id == 80) return "Red Top Hat";
        if (id == 81) return "Robot Head";
        if (id == 82) return "Roman Legionary";
        if (id == 83) return "Safari";
        if (id == 84) return "Sherlock";
        if (id == 85) return "Sombrero";
        if (id == 86) return "Sparta";
        if (id == 87) return "Steampunk";
        if (id == 88) return "Straw";
        if (id == 89) return "Straw Hat";
        if (id == 90) return "Teapot";
        if (id == 91) return "Tin Hat";
        if (id == 92) return "Toupee";
        if (id == 93) return "Valkyrie";
        if (id == 94) return "Viking";
        if (id == 95) return "White Kabuki Mask";
        if (id == 96) return "Yellow Exploding Hair";

        return "";
    }

    ////

    function _buildAttributes(
        uint256 genome,
        address chonkyAttributes,
        address chonkySet
    ) internal pure returns (string memory result) {
        uint256[12] memory attributes = ChonkyGenomeLib.parseGenome(genome);

        bytes memory buffer = abi.encodePacked(
            '"attributes":[',
            '{"trait_type":"Background",',
            '"value":"',
            _getBGBase(attributes[0]),
            '"}'
        );

        if (attributes[1] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ', {"trait_type":"Rare Background",',
                '"value":"',
                _getBGRare(attributes[1]),
                '"}'
            );
        }

        if (attributes[2] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Wings",',
                '"value":"',
                _getWings(attributes[2]),
                '"}'
            );
        }

        if (attributes[3] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Skin",',
                '"value":"',
                _getSkin(attributes[3]),
                '"}'
            );
        }

        if (attributes[4] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Pattern",',
                '"value":"',
                _getPattern(attributes[4]),
                '"}'
            );
        }

        if (attributes[5] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Paint",',
                '"value":"',
                _getPaint(attributes[5]),
                '"}'
            );
        }

        if (attributes[6] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Body",',
                '"value":"',
                _getBody(attributes[6]),
                '"}'
            );
        }

        if (attributes[7] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Mouth",',
                '"value":"',
                _getMouth(attributes[7]),
                '"}'
            );
        }

        if (attributes[8] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Eyes",',
                '"value":"',
                _getEyes(attributes[8]),
                '"}'
            );
        }

        if (attributes[9] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Hat",',
                '"value":"',
                _getHat(attributes[9]),
                '"}'
            );
        }

        if (attributes[10] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Lost King",',
                '"value":"',
                _getLostKing(attributes[10]),
                '"}'
            );
        }

        if (attributes[11] > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Honorary",',
                '"value":"',
                _getHonorary(attributes[11]),
                '"}'
            );
        }

        uint256 setId = IChonkySet(chonkySet).getSetId(genome);

        if (setId > 0) {
            buffer = abi.encodePacked(
                buffer,
                ',{"trait_type":"Full Set",',
                '"value":"',
                IChonkySet(chonkySet).getSetFromId(setId),
                '"}'
            );
        }

        uint256[4] memory attributeValues = ChonkyAttributes(chonkyAttributes)
            .getAttributeValues(attributes, setId);

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Brain",',
            '"value":',
            attributeValues[0].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Cute",',
            '"value":',
            attributeValues[1].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Power",',
            '"value":',
            attributeValues[2].toString(),
            "}"
        );

        buffer = abi.encodePacked(
            buffer,
            ',{"trait_type":"Wicked",',
            '"value":',
            attributeValues[3].toString(),
            "}"
        );

        return string(abi.encodePacked(buffer, "]"));
    }
}
