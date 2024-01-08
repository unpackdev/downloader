// SPDX-License-Identifier: MIT
//
//        _ __ ___   ___  _ __  ___| |_ ___ _ __ ___
//      | '_ ` _ \ / _ \| '_ \/ __| __/ _ \ '__/ __|
//      | | | | | | (_) | | | \__ \ ||  __/ |  \__ \
//      |_| |_| |_|\___/|_| |_|___/\__\___|_|  |___/
//
//                   ^    ^
//                  / \  //\
//    |\___/|      /   \//  .\
//    /O  O  \__  /    //  | \ \
//   /     /  \/_/    //   |  \  \
//   @___@'    \/_   //    |   \   \
//      |       \/_ //     |    \    \
//      |        \///      |     \     \
//     _|_ /   )  //       |      \     _\
//    '/,_ _ _/  ( ; -.    |    _ _\.-~        .-~~~^-.
//    ,-{        _      `-.|.-~-.           .~         `.
//     '/\      /                 ~-. _ .-~      .-~^-.  \
//        `.   {            }                   /      \  \
//      .----~-.\        \-'                 .~         \  `. \^-.
//     ///.----..>    c   \             _ -~             `.  ^-`   ^-_
//       ///-._ _ _ _ _ _ _}^ - - - - ~                     ~--,   .-~
//                                                             /.-'
//

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ILoot.sol";
import "./ILootComponents.sol";

contract Monsters is ERC721Enumerable, Ownable, ReentrancyGuard {
  uint256 public constant price = 100000000000000000; // 0.1 ETH
  ILoot public constant loot = ILoot(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
  ILootComponents public constant lootComponents = ILootComponents(0x3eb43b1545a360d1D065CB7539339363dFD445F3);

  event Slain(address indexed slayer, uint256 tokenId, uint256 lootId, string name);
  event Named(address indexed sender, uint256 tokenId, string name);

  mapping(uint256 => address) public slayerOf;
  mapping(uint256 => uint256) public slainWith;
  mapping(uint256 => string) private nameOf;

  string[] private weapons = [
    "Warhammer", // 0
    "Quarterstaff", // 1
    "Maul", // 2
    "Mace", // 3
    "Club", // 4
    "Katana", // 5
    "Falchion", // 6
    "Scimitar", // 7
    "Long Sword", // 8
    "Short Sword", // 9
    "Ghost Wand", // 10
    "Grave Wand", // 11
    "Bone Wand", // 12
    "Wand", // 13
    "Grimoire", // 14
    "Chronicle", // 15
    "Tome", // 16
    "Book" // 17
  ];

  string[] private traitCategories = [
    "Color",
    "Quirk",
    "Oddity",
    "Organ",
    "Hazard",
    "Specialty",
    "Race",
    "Personality",
    "Action",
    "Weakness",
    "Slain"
  ];

  string[] private colors = [
    "Moccasin",
    "Ivory",
    "Crimson",
    "Coral",
    "Royalblue",
    "Forestgreen",
    "Tan",
    "Firebrick",
    "Azure",
    "Burlywood",
    "Turquoise",
    "Slateblue",
    "Orchid",
    "Chartreuse",
    "Gold",
    "Aquamarine"
  ];

  string[] private quirks = [
    "Mutant",
    "One-eyed",
    "Magical",
    "Psychic",
    "Flaming",
    "Scaled",
    "Furry",
    "Metallic",
    "Two-headed",
    "Umbral",
    "Stone",
    "Horned",
    "Divine",
    "Undead",
    "Zombie",
    "Vampiric"
  ];

  string[] private oddities = [
    "Muscular",
    "Webbed",
    "Bulging",
    "Blubbery",
    "Toxic",
    "Baggy",
    "Acidic",
    "Cursing",
    "Slimy",
    "Serrated",
    "Alcoholic",
    "Putrid",
    "Splintering",
    "Blinding",
    "Seductive",
    "Molten"
  ];

  string[] private organs = [
    "Frill",
    "Mandibles",
    "Gills",
    "Crown",
    "Camouflage",
    "Quills",
    "Lungs",
    "Snout",
    "Armour",
    "Spores",
    "Parasites",
    "Eggs",
    "Fire",
    "Breath",
    "Bile",
    "Jaws"
  ];

  string[] private hazards = [
    "Deadly",
    "Lava",
    "Tiny",
    "Spiky",
    "Humongous",
    "Sentient",
    "Crushing",
    "Smelly",
    "Poisonous",
    "Sharp",
    "Enormous",
    "Quick",
    "Riveting",
    "Strange",
    "Petrifying",
    "Unstable"
  ];

  string[] private specialties = [
    "Blood",
    "Sweat",
    "Thorns",
    "Webs",
    "Claws",
    "Eye",
    "Wings",
    "Arms"
    "Hair",
    "Tail",
    "Song",
    "Shout",
    "Gaze",
    "Mood",
    "Vapors",
    "Wink"
  ];

  string[] private races = [
    "Manticore",
    "Dragon",
    "Minotaur",
    "Phoenix",
    "Hydra",
    "Gorgon",
    "Titan",
    "Ape",
    "Harpy",
    "Griffin",
    "Goblin",
    "Penguin",
    "Basilisk",
    "Kobold",
    "Cyclops",
    "Slime"
  ];

  string[] private personalities = [
    "Rare",
    "Confused",
    "Bored",
    "Elusive",
    "Pudgy",
    "Cute",
    "Hungry",
    "Mad",
    "Lost",
    "Ancient",
    "Mythic",
    "Forgotten",
    "Battleworn",
    "Peaceful",
    "Endangered",
    "Cursed"
  ];

  string[] private actions = [
    "Grins",
    "Sleeps",
    "Groans",
    "Dances",
    "Awakens",
    "Undulates",
    "Flies",
    "Sings",
    "Feasts",
    "Sees",
    "Listens",
    "Roams",
    "Hides",
    "Stalks",
    "Speaks",
    "Thinks"
  ];

  function mintWithLoot(uint256 lootId) public nonReentrant {
    require(lootId > 0 && lootId <= 8000, "Invalid ID");
    require(msg.sender == loot.ownerOf(lootId), "Not loot owner");
    _safeMint(_msgSender(), lootId);
  }

  function mint(uint256 tokenId) public payable nonReentrant {
    require(tokenId > 0 && tokenId <= 9800, "Invalid ID");
    require(price <= msg.value, "Insufficient Ether");
    _safeMint(_msgSender(), tokenId);
  }

  function reservedMint(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId > 9800 && tokenId <= 10000, "Invalid ID");
    _safeMint(_msgSender(), tokenId);
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function lootOwnerOf(uint256 lootId) external view returns (address) {
    return loot.ownerOf(lootId);
  }

  function getName(uint256 tokenId) public view returns (string memory) {
    string storage name = nameOf[tokenId];
    return (bytes(name).length != 0) ? name : string(abi.encodePacked("Monster #", uint2str(tokenId)));
  }

  function getColor(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "color", colors);
  }

  function getPersonality(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "personality", personalities);
  }

  function getQuirk(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "quirk", quirks);
  }

  function getRace(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "race", races);
  }

  function getAction(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "action", actions);
  }

  function getOddity(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "oddity", oddities);
  }

  function getOrgan(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "organ", organs);
  }

  function getHazard(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "hazard", hazards);
  }

  function getSpecialty(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "specialty", specialties);
  }

  function getWeakness(uint256 tokenId) public view returns (string memory) {
    return weapons[getWeaknessType(tokenId)];
  }

  function canSlay(uint256 tokenId, uint256 lootId) public view returns (bool) {
    return getWeaknessType(tokenId) == lootComponents.weaponComponents(lootId)[0];
  }

  function slay(
    uint256 tokenId,
    uint256 lootId,
    string calldata name
  ) public {
    require(msg.sender == loot.ownerOf(lootId), "Not loot owner");
    require(canSlay(tokenId, lootId), "Immune");
    setName(tokenId, name);
    slayerOf[tokenId] = msg.sender;
    slainWith[tokenId] = lootId;
    emit Slain(msg.sender, tokenId, lootId, name);
  }

  function setName(uint256 tokenId, string calldata name) public {
    require(!isSlain(tokenId), "Already slain");
    require(msg.sender == ownerOf(tokenId), "Not monster owner");
    require(bytes(name).length <= 32, "Name > 32 chars");
    nameOf[tokenId] = name;
    emit Named(msg.sender, tokenId, name);
  }

  function getNameLabel(uint256 tokenId) internal view returns (string memory) {
    string storage name = nameOf[tokenId];
    if (bytes(name).length != 0) {
      return name;
    } else {
      return "An unknown Monster";
    }
  }

  function getStatusLabel(uint256 tokenId) internal view returns (string memory) {
    return slayerOf[tokenId] == address(0) ? "Alive" : getSlayingWeaponMessage(tokenId);
  }

  function isSlain(uint256 tokenId) internal view returns (bool) {
    return slayerOf[tokenId] != address(0);
  }

  function getSlayingWeaponMessage(uint256 tokenId) internal view returns (string memory) {
    return
      slayerOf[tokenId] == address(0)
        ? ""
        : string(abi.encodePacked("Slain with Loot #", uint2str(tokenId), " ", loot.getWeapon(slainWith[tokenId])));
  }

  function pluck(
    uint256 tokenId,
    string memory keyPrefix,
    string[] memory sourceArray
  ) internal pure returns (string memory) {
    uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
    string memory output = sourceArray[rand % sourceArray.length];
    return output;
  }

  function generateCard(uint256 tokenId) internal view returns (string memory) {
    string memory color = getColor(tokenId);
    return
      string(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }.small { font-size: 10px; }',
          ".colored { fill:",
          color,
          '}</style><rect width="100%" height="100%" fill="black" stroke="',
          color,
          '" stroke-width="5px" /><text text-anchor="end" x="340" y="20" class="base" font-weight="bold">#',
          uint2str(tokenId),
          '</text><text x="10" y="20" class="base" font-weight="bold">'
        )
      );
  }

  function getWeaknessType(uint256 tokenId) internal view returns (uint256) {
    uint256 rand = random(string(abi.encodePacked("weakness", toString(tokenId))));
    return rand % weapons.length;
  }

  function generateDangerInfo(uint256 tokenId) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(
          '.</text><text x="10" y="180" class="base">',
          string(abi.encodePacked("It possesses ", getOddity(tokenId), " ", getOrgan(tokenId), ".")),
          '</text><text x="10" y="200" class="base">',
          string(abi.encodePacked("Beware its ", getHazard(tokenId), " ", getSpecialty(tokenId), "!")),
          '</text><text x="10" y="220" class="base">',
          string(abi.encodePacked("It is weak to ", getWeakness(tokenId), "s.")),
          '</text><text x="10" y="280" class="base small">'
        )
      );
  }

  function traitsOf(uint256 tokenId) public view returns (string memory) {
    string[11] memory traitValues = [
      getColor(tokenId),
      getQuirk(tokenId),
      getOddity(tokenId),
      getOrgan(tokenId),
      getHazard(tokenId),
      getSpecialty(tokenId),
      getRace(tokenId),
      getPersonality(tokenId),
      getAction(tokenId),
      getWeakness(tokenId),
      isSlain(tokenId) ? "Yes" : "No"
    ];
    string memory resultString = "[";
    for (uint8 j = 0; j < traitCategories.length; j++) {
      if (j > 0) {
        resultString = strConcat(resultString, ", ");
      }
      resultString = strConcat(resultString, '{"trait_type": "');
      resultString = strConcat(resultString, traitCategories[j]);
      resultString = strConcat(resultString, '", "value": "');
      resultString = strConcat(resultString, traitValues[j]);
      resultString = strConcat(resultString, '"}');
    }
    return strConcat(resultString, "]");
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string[15] memory parts;

    parts[0] = generateCard(tokenId); // solhint-disable-line
    parts[1] = getNameLabel(tokenId);
    parts[2] = '</text><text x="10" y="60" class="base colored">';
    parts[3] = getColor(tokenId);
    parts[4] = '</text><text x="10" y="80" class="base">';
    parts[5] = getPersonality(tokenId);
    parts[6] = '</text><text x="10" y="100" class="base">';
    parts[7] = getQuirk(tokenId);
    parts[8] = '</text><text x="10" y="120" class="base">';
    parts[9] = getRace(tokenId);
    parts[10] = '</text><text x="10" y="160" class="base"> It ';
    parts[11] = getAction(tokenId);
    parts[12] = generateDangerInfo(tokenId);
    parts[13] = getStatusLabel(tokenId);
    parts[14] = "</text></svg>";

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
    );
    output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            getName(tokenId),
            '", "description": "Monsters are randomized forgotten beasts generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Slay them if you can - with the right Loot! Feel free to use Monsters in any way you want.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '", "attributes": ',
            traitsOf(tokenId),
            "}"
          )
        )
      )
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));
    return output;
  }

  function toString(uint256 value) internal pure returns (string memory) {
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

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
    return string(abi.encodePacked(bytes(_a), bytes(_b)));
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  constructor() ERC721("Monsters", "MNST") Ownable() {}
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
