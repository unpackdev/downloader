// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Floot is ERC721Enumerable, ReentrancyGuard, Ownable {
    address public beneficiary;

    uint256 public maxSupply = 8008;

    uint256 public price = 10000000000000000; //.01 ETH

    uint256 private reserved = 8;

    string[] private backgrounds = [
        "#000000", // Black
        "#0000ff", // Blue
        "#01ff01", // Green
        "#1b9aaa"  // Cyan
    ];

    string[] private genres = [
        "Ambient",
        "Bluegrass",
        "Blues",
        "Country",
        "Death Metal",
        "Disco",
        "Dubstep",
        "Elevator",
        "Emo",
        "Folk",
        "Funk",
        "Hip-Hop",
        "Jazz",
        "K-Pop",
        "Metal",
        "Pop",
        "Punk",
        "R&B",
        "Reggae",
        "Reggaeton",
        "Rock",
        "Ska",
        "Soul",
        "Trance",
        "Vaporwave"
    ];

    string[] private instruments = [
        "Acoustic Guitar",
        "Bagpipes",
        "Banjo",
        "Bass Guitar",
        "Cello",
        "Clarinet",
        "Cowbell",
        "Digeridoo",
        "Drums",
        "Electric Guitar",
        "Flute",
        "Gong",
        "Harmonica",
        "Harp",
        "Harpsichord",
        "Jew's Harp",
        "Kazoo",
        "LUTE",
        "Mandolin",
        "Organ",
        "Pennywhistle",
        "Piano",
        "Saxophone",
        "Sitar",
        "String Section",
        "Synthesizer",
        "Trombone",
        "Trumpet",
        "Tuba",
        "Ukelele",
        "Upright Bass",
        "Violin"
    ];

    string[] private notes = [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "A#",
        "C#",
        "D#",
        "F#",
        "G#",
        "Ab",
        "Bb",
        "Db",
        "Eb",
        "Gb"
    ];

    string[] private owners = [
        "3F Music",
        "Anguila",
        "Barthazian",
        "Beanie",
        "BeetsDAO",
        "ChubbyAvocado",
        "Coldsnap",
        "Crow",
        "DCinvestor",
        "Eight8Eight",
        "Film",
        "Four Poops",
        "GFunk",
        "iFirebrand",
        "Jabulon",
        "Jimbo",
        "MJdata",
        "Mondoir",
        "OGDAO",
        "SportsCheetah",
        "The Arrival",
        "Tyler Mulvi",
        "Westcoast Bill",
        "Scam DAO"
    ];

    string[] private projects = [
        "Adam Bomb Squad",
        "Animetas",
        "Art Blocks",
        "Avastars",
        "Axie Infinity",
        "Bastard Gan Punks",
        "Bloot",
        "Bored Ape Yacht Club",
        "Cool Cats",
        "Creature World",
        "CryptoPunks",
        "CryptoKitties",
        "CyberKongz",
        "Deafbeef",
        "Euler Beats",
        "FameLadySquad",
        "Ghxsts",
        "Gods Unchained",
        "Gutter Cat Gang",
        "Hashmasks",
        "I'm Spottie",
        "Koala Intelligence Agency",
        "Loot",
        "Meebits",
        "MetaHero Identities",
        "Mooncats",
        "Mutant Ape Yacht Club",
        "Nouns",
        "ON1 Force",
        "Pudgy Penguins",
        "Purrnelopes Country Club",
        "Robotos",
        "SupDucks",
        "Song a Day",
        "Stoner Cats",
        "The Doge Pound",
        "Tools of Rock",
        "Top Dog Beach Club",
        "Wicked Craniums",
        "World of Women",
        "Veefriends",
        "Vogu",
        "Zed Run"
    ];

    string[] private tempos = [
        "Adagietto (65-69 BPM)",
        "Adagio (55-65 BPM)",
        "Allegretto (98-109 BPM)",
        "Allegro (109-132 BPM)",
        "Andante (73-77 BPM)",
        "Beanie's Twitter Fingers Fast (169 BPM)",
        "Bearish Tempo (50 BPM)",
        "Boolish Tempo (95 BPM)",
        "Fast AF (175 BPM)",
        "Grave (20-40 BPM)",
        "Largo (45-50 BPM)",
        "Lento (40-45 BPM)",
        "Moderato (86-97 BPM)",
        "Netflix And Chill (69 BPM)",
        "Parabolic Pump Speed (201+ BPM)",
        "Prestissimo (178 BPM-200 BPM)",
        "Presto (168-177 BPM)",
        "Stoner Vibes (42.0 BPM)",
        "Vivace (132-140 BPM)"
    ];

    string[] private lyrics = [
        ", Like A Rolling Ether Rock",
        "'s Got a Gun",
        " Will Bloot You Like an Animal",
        " Rugged The Police",
        "'s Roadmap is Trash",
        ", Shut Up And Rug Me",
        " Oops, I Blooted",
        " Stay Boolish",
        " Gang Gang",
        " is NGMI",
        " Wen?",
        " is Proof Of Ape",
        " Re-tweeted WGMI",
        " vs. Vitalik in Abudabi",
        " sold Art Blocks",
        " Big Pimpin' Up In BAYC",
        " killed Satoshi",
        "'s Bitcoin Pizza",
        " Jams Blitzkrieg Punk",
        " shops on BrokenSea",
        " Is In Love With A JPEG",
        "'s Family DeFi Summer Vacation",
        " Snitched on Mt. Gox",
        " invented Proof Of Shit"
        " Tweets GM, Wizards",
        " Rugged CZ",
        " Refused to sign the Multisig",
        " was accused of being a Scam DAO"
    ];

    constructor(address _beneficiary) ERC721("FLOOT Musical Cards", "FLOOT") Ownable() {
        beneficiary = _beneficiary;
    }

    function claim(uint256 _tokenId) public payable nonReentrant {
        require(_tokenId < maxSupply - reserved, "Invalid Token ID");
        require(!_exists(_tokenId), "Token ID already exists");
        require(price == msg.value, "Incorrect payment amount");

        _safeMint(_msgSender(), _tokenId);
        payable(beneficiary).transfer(msg.value);
    }

    function reserve(address[] memory _recipients, uint256[] memory _tokenIds) public onlyOwner {
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (tokenId < maxSupply && !_exists(tokenId)) {
                _safeMint(_recipients[i], _tokenIds[i]);
            }
        }
    }

    function changeBeneficiary() public onlyOwner {
        
    }
    
    function getBackground(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(_tokenId, "background");
        return backgrounds[rand % backgrounds.length];
    }

    function getGenre(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(_tokenId, "genre");
        rand = rand % 51;
        
        if (rand > 40) {
            string memory genre = genres[rand % genres.length];
            string memory project = projects[rand % projects.length];
            return string(abi.encodePacked(project, " ", genre));
        }

        return genres[rand % genres.length];
    }

    function getLyric(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(_tokenId, "lyric");
        string memory owner = owners[rand % owners.length];
        string memory lyric = lyrics[rand % lyrics.length];

        return string(abi.encodePacked(owner, lyric));
    }

    function getInstrument(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(_tokenId, "instrument");
        return instruments[rand % instruments.length];
    }

    function getTempo(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(_tokenId, "tempo");
        return tempos[rand % tempos.length];
    }

    function getSheet(uint256 _tokenId) public view returns (string memory) {
        string memory sheet;
        uint256 length = (random(_tokenId, "sheet") % 4) + 4;

        for (uint256 i = 0; i < length; i++) {
            uint256 rand = random(_tokenId + i, "note");
            string memory note = notes[rand % notes.length];
            sheet = string(abi.encodePacked(sheet, " ", note));
        }

        return sheet;
    }

    function random(uint256 _tokenId, string memory _keyPrefix) internal pure returns (uint256) {
        bytes memory abiEncoded = abi.encodePacked(_keyPrefix, toString(_tokenId));
        return uint256(keccak256(abiEncoded));
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        string[15] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: monospace; font-size: 14px; }</style><rect width="100%" height="100%" fill="';
        parts[1] = getBackground(_tokenId);

        parts[2]  = '" /><text x="10" y="20" class="base">';
        parts[3] = getGenre(_tokenId);

        parts[4] = '</text><text x="10" y="40" class="base">';
        parts[5] = getLyric(_tokenId);

        parts[6] = '</text><text x="10" y="60" class="base">';
        parts[7] = getInstrument(_tokenId);

        parts[8] = '</text><text x="10" y="80" class="base">';
        parts[9] = getTempo(_tokenId);

        parts[10] = '</text><text x="10" y="100" class="base">';
        parts[11] = getSheet(_tokenId);

        parts[12] = '</text><text x="300" y="330" class="base">';
        parts[13] = toString(_tokenId);

        parts[14] = "</text></svg>";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "FLOOT #', toString(_tokenId), '", "description": "$FLOOT Musical Cards, on-chain randomly generated cards that you can use any way you want. Perhaps you challenge your song writing skills? Challenge another musician? Writer\'s block? We have all been there. Sometimes what you need is inspiration, and sometimes you just need a nudge. $FLOOT can be both and more.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

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
