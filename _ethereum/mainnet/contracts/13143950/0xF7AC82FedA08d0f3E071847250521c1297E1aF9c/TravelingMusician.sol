/**
 *Submitted for verification at Etherscan.io on 2021-08-27
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface LootInterface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract TravelingMusician is ERC721Enumerable, ReentrancyGuard, Ownable {
  uint256 public lootPrice = 200000000000000000; //0.2 ETH
  uint256 public price = 500000000000000000; //0.5 ETH

  //Loot Contract
  address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
  LootInterface public lootContract = LootInterface(lootAddress);

  string[] private songList = [
    "ipfs://QmaDc5ecEYSjhfA8pVswbSQRgxJuSAeSBTZdQBq12HbEQ1",
    "ipfs://QmRDNu6Hhs8VL9RpfUgeeHoVq3FXNG1vGruCTBvWSoo1au",
    "ipfs://Qmdc8gU5hm2wuxDMuHw9TY3McBwXQFrZzDBZJvBNwaAEUs",
    "ipfs://QmRU9QBoBD1n7J6npwZntqFf2vTJCQVYKwA6Daj31TNVQB",
    "ipfs://Qmbf3EBVqc6EGh4h3vAvCiCiTH7BYXgSEr2hGNQhEF76cU",
    "ipfs://QmT4dcdzsAK6HvjmXrTJuNDwjPFTgkVbXgGLQ1CaGRwRUm"
  ];

  string[] private songs = [
    "Exploring without Aim",
    "Through Hell's Gate",
    "Time for a Slumber",
    "Towards the Quest before Us",
    "Enter the Dungeon",
    "A Vision Before Us"
  ];

  string[] private vocalRanges = ["Soprano", "Mezzo-Soprano", "Tenor", "Baritone", "Bass", "Countertenor"];

  string[] private singingStyles = [
    "Whispering",
    "Humming",
    "Melodic",
    "Whistling",
    "Yelling",
    "Belch",
    "Storytelling",
    "Choir Voice",
    "Monotone",
    "Tone Deaf",
    "Falsetto",
    "Gregarious",
    "Acappella",
    "Grungy",
    "Yodel",
    "Trill",
    "Chanting"
    "Slow Spoken",
    "Rhythmic Cadence",
    "Vibrato",
    "Poetic Verse"
  ];

  string[] private proficiencies = [
    "Virtuoso",
    "Maestro",
    "Expert",
    "Prodigy",
    "Apprentice",
    "Intermediate",
    "Student",
    "Novice",
    "Beginner",
    "Pretender"
  ];

  string[] private famousSongs = [
    "A River and Two Stones",
    "Over the Hill Top Castle",
    "A Sword through the Eye",
    "The Walls that Never Fell",
    "Dragons in My Bed",
    "Fountains I bathed In",
    "Helm and Shield",
    "The Crown Above My Head",
    "Knew Not What I Conquered",
    "To Rule with the Heart of a Lion",
    "A Beast in the Dark Forest",
    "A Table for my Friends and Me",
    "Stumbling from Door to Door",
    "My Horse is All That's Left",
    "Highlords below my feet",
    "The Hidden Knife",
    "A Dungeon within My House",
    "10 Rings are Not Enough",
    "A Voyage to The Isles of Breverton"
    "Into the Fold",
    "Against the Che'Dure Army",
    "Treachery No More",
    "Dancing with Tears",
    "End of the Letru's Grave",
    "Seventeen Thousand against One",
    "Bulle's Surprise"
  ];

  string[] private instruments = [
    "Accordion",
    "Bagpipe",
    "Banjo",
    "Bell",
    "Bugle",
    "Cello",
    "Clarinet",
    "Cornet",
    "Cymbal",
    "Flute",
    "French horn",
    "Gong",
    "Guitar",
    "Harmonica",
    "Harp",
    "Mandolin",
    "Marimba",
    "Oboe",
    "Organ",
    "Pan flute",
    "Piano",
    "Sitar",
    "Tambourine",
    "Triangle",
    "Trumpet",
    "Violin"
  ];

  string[] private infamy = [
    "World Renowned",
    "Provincial Notoriety",
    "Queen's Hand",
    "King's Jester",
    "Household Name",
    "Town Performer",
    "Court Gossip",
    "Rotten Tomato",
    "Traveler's Tale",
    "Stage Performer",
    "Prominent Musician",
    "Unknown"
  ];

  string[] private demeanor = [
    "Absentminded",
    "Aggressive",
    "Ambitious",
    "Amusing",
    "Artful",
    "Clumsy",
    "Disrespectful",
    "Lazy",
    "Superstitious",
    "Troublesome",
    "Captivating",
    "Courageous",
    "Creative",
    "Humorous",
    "Loyal",
    "Lyrical",
    "Modest",
    "Sage",
    "Stoic",
    "Clever",
    "Sly",
    "Skillful",
    "Quirky",
    "Witty"
    "Impulsive",
    "Deceitful",
    "Cowardly",
    "Mystical",
    "Heroic",
    "Intelligent",
    "Playful"
  ];

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getSongFromList(string memory songName) internal view returns (string memory) {
    if (keccak256(bytes(songName)) == keccak256(bytes("Through Hell's Gate"))) {
      return songList[0];
    } else if (keccak256(bytes(songName)) == keccak256(bytes("Towards the Quest before Us"))) {
      return songList[1];
    } else if (keccak256(bytes(songName)) == keccak256(bytes("Exploring without Aim"))) {
      return songList[2];
    } else if (keccak256(bytes(songName)) == keccak256(bytes("Time for a Slumber"))) {
      return songList[3];
    } else if (keccak256(bytes(songName)) == keccak256(bytes("Enter the Dungeon"))) {
      return songList[4];
    } else {
      return songList[1];
    }
  }

  function getSong(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "SONG", songs);
  }

  function getVocalRange(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "VOCAL", vocalRanges);
  }

  function getSingingStyle(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "STYLE", singingStyles);
  }

  function getFamousSongs(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "FOLKLORE", famousSongs);
  }

  function getInstrument(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "INSTRUMENT", instruments);
  }

  function getProficiency(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "MUSICAL PROFICIENCY", proficiencies);
  }

  function getInfamy(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "INFAMY", infamy);
  }

  function getDemeanor(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "DEMEANOR", demeanor);
  }

  function pluck(
    uint256 tokenId,
    string memory keyPrefix,
    string[] memory sourceArray
  ) internal view returns (string memory) {
    uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
    string memory output = sourceArray[rand % sourceArray.length];
    return output;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string[17] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

    parts[1] = getSong(tokenId);
    parts[2] = '</text><text x="10" y="40" class="base">';
    parts[3] = getVocalRange(tokenId);
    parts[4] = '</text><text x="10" y="60" class="base">';
    parts[5] = getSingingStyle(tokenId);
    parts[6] = '</text><text x="10" y="80" class="base">';
    parts[7] = getFamousSongs(tokenId);
    parts[8] = '</text><text x="10" y="100" class="base">';
    parts[9] = getInstrument(tokenId);
    parts[10] = '</text><text x="10" y="120" class="base">';
    parts[11] = getProficiency(tokenId);
    parts[12] = '</text><text x="10" y="140" class="base">';
    parts[13] = getInfamy(tokenId);
    parts[14] = '</text><text x="10" y="160" class="base">';
    parts[15] = getDemeanor(tokenId);
    parts[16] = "</text></svg>";

    string memory output =
      string(
        abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
      );
    output = string(
      abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16])
    );

    string memory song = getSongFromList(parts[1]);

    string memory json =
      Base64.encode(
        bytes(
          string(
            abi.encodePacked(
              '{"name": "Traveling Musician: Songs of the Metaverse #',
              toString(tokenId),
              '", "description": "Each Traveling Musician carries a theme song. You can find the song in the tokenURI. Compatible with Loot (for Adventurers)", "song": "',
              song,
              '", "image": "data:image/svg+xml;base64,',
              Base64.encode(bytes(output)),
              '"}'
            )
          )
        )
      );

    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
  }

  function mint(uint256 tokenId) public payable nonReentrant {
    require(tokenId > 3000 && tokenId <= 5000, "Token ID invalid");
    require(price <= msg.value, "Ether value sent is not correct");
    _safeMint(_msgSender(), tokenId);
  }

  function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
    require((price * tokenIds.length) <= msg.value, "Ether value sent is not correct");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(tokenIds[i] > 3000 && tokenIds[i] < 5000, "Token ID invalid");
      _safeMint(msg.sender, tokenIds[i]);
    }
  }

  function mintWithLoot(uint256 lootId) public payable nonReentrant {
    require(lootId > 0 && lootId <= 3000, "Token ID invalid");
    require(lootPrice <= msg.value, "Ether value sent is not correct");
    require(lootContract.ownerOf(lootId) == msg.sender, "Not the owner of this loot");
    _safeMint(_msgSender(), lootId);
  }

  function multiMintWithLoot(uint256[] memory lootIds) public payable nonReentrant {
    require((lootPrice * lootIds.length) <= msg.value, "Ether value sent is not correct");

    for (uint256 i = 0; i < lootIds.length; i++) {
      require(lootContract.ownerOf(lootIds[i]) == msg.sender, "Not the owner of this loot");
      _safeMint(_msgSender(), lootIds[i]);
    }
  }

  function withdraw() public onlyOwner {
    payable(0x2444D43384f7573d212F3559a30064a31121c9F9).transfer(address(this).balance);
  }

  function setLootersPrice(uint256 newPrice) public onlyOwner {
    lootPrice = newPrice;
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
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

  constructor() ERC721("Traveling Musician", "TRAVELING_MUSICIAN") Ownable() {}
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
