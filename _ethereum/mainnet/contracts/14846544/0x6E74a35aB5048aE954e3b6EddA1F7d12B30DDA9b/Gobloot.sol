// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

contract Gobloot is ERC721Enumerable, ReentrancyGuard {
    string[] private boddee = [
        "Flappy",
        "Dawwww",
        "Dat spase soot gots holes",
        "Clubbin time",
        "Fansee",
        "Sashay",
        "Furr",
        "Wanna poak dat",
        "Blarggh",
        "Ouchies",
        "Wekkum tarbys",
        "Yur mom",
        "Shy gobblin",
        "Grey body",
        "RRRRRRAAAAAHHH",
        "Stukinda troat",
        "Inna bun",
        "Diamondhands?",
        "Teeheehee",
        "ETH",
        "New Tattoo",
        "Yaris pleeze",
        "REKT",
        "Eeeeeeeeboooom"
    ];

    string[] private eers = [
        "EERS",
        "Earrz",
        "Eors",
        "724",
        "Eeerbonez",
        "Eer",
        "Earz",
        "Eerz?",
        "Eerchompr",
        "Eirs",
        "Iers",
        "Floaty eerz",
        "Eeeeers",
        "Eermoffs",
        "LAAAAAZZER EERS",
        "Woodywood eers",
        "Onny a fleshwoond",
        "Warin der farree",
        "Blingyfaweez",
        "Leefs",
        "Buttfly eerz"
    ];

    string[] private eyeOnDatSide = [
        "I seend a mouse! yum!",
        "Das not eyz eeder",
        "Hlo",
        "Nspektin stuff",
        "Whaja say?",
        "GrrrAAAAAuuugh",
        "Nar",
        "Peep",
        "Zoweee",
        "Browney",
        "Gathp",
        "Pinkypinkpink",
        "Gooness",
        "Zoinks",
        "Oook",
        "Don lookitme",
        "Wass dat way",
        "Suthpithus",
        "Not enthuzd",
        "Narf",
        "Angreye",
        "Tremblr",
        "Whoaz me",
        "Termigooblin",
        "Look dis way",
        "Waaah",
        "LAZZARZZZZ"
    ];

    string[] private eyzOnDisSide = [
        "Ooooh",
        "Ooop",
        "Krazed",
        "Lookit dat",
        "Hangded over",
        "Look up dere",
        "Seepy",
        "Sparples",
        "Transeded",
        "Eeeeeediot",
        "O noooooo",
        "Yallo",
        "Eh?",
        "Spooky",
        "Lookin dere",
        "Lookin down",
        "Eeep",
        "Upside downside",
        "Das not an eyez!",
        "Grekd",
        "Squintee",
        "Glowcoma",
        "Hipnoatisn",
        "Punchded",
        "Lookin hear",
        "Blindeded",
        "Teeny peephoal",
        "Wass overder?",
        "LAZERRR"
    ];

    string[] private hedz = [
        "Growf",
        "Flatface",
        "Cracky",
        "Soft pare",
        "Kiwimonstr",
        "Wart top",
        "Taterhead",
        "Bierdy",
        "Deflateded",
        "Jawboymangirl",
        "Bumpynoggn",
        "Oweee",
        "Avvokado",
        "Floppee",
        "Furrrrrrrrrr",
        "SPIKR",
        "STABBYSTABHEAD",
        "TAK UR ORDRR?"
    ];

    string[] private munchyHole = [
        "Mouf",
        "Mubblebumm",
        "Blablabla",
        "Blippyblipblipblip",
        "Ibblebiddle",
        "Aaaabaaaaabbbaaa",
        "Oobie doo",
        "Nuddernuddermouf",
        "Mouffs",
        "Gaaahhh",
        "Glaaaaaah",
        "Bleebleebloobloo",
        "Mrnnhrhmn",
        "Gooooooo",
        "Nudder mouf",
        "Nomnomhole",
        "Burblurblurb",
        "LAZERBARRF"
    ];

    string[] private collrzes = [
        "Kobold puke",
        "Mold",
        "Nothin",
        "Purdy cave",
        "FLEsh stik",
        "Wat dis?",
        "Dirt",
        "Bloody milk yumm",
        "Fludded tunlz",
        "Darkderest",
        "Stupid color",
        "Darkerer",
        "Rottn elfboddie",
        "Stupid sun"
    ];

    string[] private stankfinder = [
        "Bloo",
        "Goz down",
        "Berries",
        "Udder pointy kind",
        "Sniffer",
        "Ouchie",
        "Zippyzipzip",
        "Flassid",
        "Das notta nose",
        "Dizeezsd",
        "Blobby",
        "Danglydoo",
        "Shnozz",
        "Funny",
        "Crooky",
        "Droopy",
        "Pointy",
        "Is dat a nose",
        "Dribble",
        "Uppy",
        "Buttnose",
        "Arouzd",
        "Kwaigun",
        "LAAAYZERSNOT"
    ];

    string[] private hedzSuffixes = [
        "of Shiny",
        "of Gerry pee",
        "of Nom",
        "of Nofaks Gibben"
    ];

    string[] private stankfinderSuffixes = [
        "of Maaaagic",
        "of Deep shinies finding",
        "of Snotting",
        "of Putrid smelz",
        "of Dung"
    ];
    string[] private munchyHoleSuffixes = [
        "of Munchin",
        "of Stinky breaths",
        "of BLRRGHGHHH",
        "of Shouting",
        "of Whispering"
    ];
    string[] private eersSuffixes = [
        "of Wax",
        "of Hearing",
        "of Sock flinging",
        "of Eeeek"
    ];

    function kindaRand(string memory dis) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(dis)));
    }

    function gibBoddee(uint256 dat) public view returns (string memory) {
        return pluck(dat, "BODDEE", boddee, 1);
    }

    function gibEers(uint256 dat) public view returns (string memory) {
        return pluck(dat, "EERS", eers, 2);
    }

    function gibEyeOnDatSide(uint256 dat) public view returns (string memory) {
        return pluck(dat, "EYE ON DAT SIDE", eyeOnDatSide, 3);
    }

    function gibEyzOnDisSide(uint256 dat) public view returns (string memory) {
        return pluck(dat, "EYZ ON DIS SIDE", eyzOnDisSide, 4);
    }

    function gibHedz(uint256 dat) public view returns (string memory) {
        return pluck(dat, "HEDZ", hedz, 5);
    }

    function gibMunchyHole(uint256 dat) public view returns (string memory) {
        return pluck(dat, "MUNCHYHOLE", munchyHole, 6);
    }

    function gibCollrzes(uint256 dat) public view returns (string memory) {
        return pluck(dat, "COLLRZES", collrzes, 7);
    }

    function gibStankFinder(uint256 dat) public view returns (string memory) {
        return pluck(dat, "STANKFINDER", stankfinder, 8);
    }

    function pluck(uint256 dat, string memory shinyKey, string[] memory daSource, uint8 watKeyIsDis) internal view returns (string memory) {
        uint256 rand = kindaRand(string(abi.encodePacked(shinyKey, toString(dat))));
        string memory output = daSource[rand % daSource.length];
        uint256 gibRare = rand % 21;
        string[1] memory goblinParts;
        if (gibRare < 18) {
            output = string(abi.encodePacked(output));
        }
        if (gibRare >= 19) {
            if (watKeyIsDis == 1) {
                goblinParts[0] = eersSuffixes[rand % eersSuffixes.length];
            }
            if (watKeyIsDis == 4) {
                goblinParts[0] = hedzSuffixes[rand % hedzSuffixes.length];
            }
            if (watKeyIsDis == 5) {
                goblinParts[0] = munchyHoleSuffixes[rand % munchyHoleSuffixes.length];
            }
            if (watKeyIsDis == 7) {
                goblinParts[0] = stankfinderSuffixes[rand % stankfinderSuffixes.length];
            }
            if (gibRare == 19) {
                output = string(abi.encodePacked(output,' ', goblinParts[0], ' +1'));
            }
            if (gibRare == 20) {
                output = string(abi.encodePacked(output,' ', goblinParts[0], ' +2'));
            }
        }
        return output;
    }
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: helvetica,serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#000000" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked('Boddee: ', gibBoddee(tokenId)));

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = string(abi.encodePacked('Eers: ', gibEers(tokenId)));

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = string(abi.encodePacked('Eye on dat side: ', gibEyeOnDatSide(tokenId)));

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = string(abi.encodePacked('Eyz on dis side: ', gibEyzOnDisSide(tokenId)));

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = string(abi.encodePacked('Hedz: ', gibHedz(tokenId)));

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = string(abi.encodePacked('Munchyhole: ', gibMunchyHole(tokenId)));

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = string(abi.encodePacked('Collrzes: ', gibCollrzes(tokenId)));

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = string(abi.encodePacked('Stankfinder: ', gibStankFinder(tokenId)));

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Goblin #', toString(tokenId), '", "description": "AAAAAAAUUUUUGGGHHHHH gobblins goblinns GOBLINNNNNNNNns LOOOOOOTS", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function gibGobloot(uint256 tokenId) public nonReentrant {
        require(tx.origin == msg.sender, "Only gib to huuuumanz");
        require(tokenId < 10000, "No more gib");
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

    constructor() ERC721("Gobloot", "GOBLOOT") {}
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
