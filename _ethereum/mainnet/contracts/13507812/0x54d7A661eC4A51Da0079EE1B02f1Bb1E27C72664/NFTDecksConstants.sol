// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./strings.sol";

/**
 * @title NFTDecksConstants
 *
 * @notice External library for constants used by NFTDecks
 *
 *  This is an external library in order to keep the main contract within the bytecode limit.
 *
 *  Based closely on the original Loot implementation (MIT License).
 *  https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1
 *  The CSV optimization is owed to zefram.eth.
 */
library NFTDecksConstants {
  using strings for string;
  using strings for strings.slice;

  enum ListName {
    WEAPON,
    CHEST,
    HEAD,
    WAIST,
    FOOT,
    HAND,
    WEAPON2,
    WEAPON3,
    SUFFIX,
    NAME_PREFIX,
    NAME_SUFFIX
  }

  string internal constant WEAPONS = "Imperial Rusty trident,Lucifers Gladius,Merciless Excalibur Sword,Ruthless Swine BroadAxe,Diabolical Short Sword, Excalibur, Cowards Blade, Galatine, Rhongomiant";
  uint256 internal constant WEAPONS_LENGTH = 9;

  string internal constant CHEST_ARMOR = "Divine Vest,Silk Vest,Linen Vest,Vest,Dragonskin Jacket,Demon Husk,Dragonskin Armor,Studded Leather Armor,Hard Leather Armor,Leather Armor,Legandary Chestplate,Iron Chestplate,Plate Mail,Chain Mail,Ring Mail";
  uint256 internal constant CHEST_ARMOR_LENGTH = 15;

  string internal constant HEAD_ARMOR = "Impregnable Helm, Ancient Helm,Ornate Helm,Great Helm,Full Helm,Helm,Demon Crown,Dragon's Crown,War Cap,Leather Cap,Cap,Crown,Divine Hood,Silk Hood,Linen Hood,Hood";
  uint256 internal constant HEAD_ARMOR_LENGTH = 16;

  string internal constant WAIST_ARMOR = "Impregnable Sash, Ornate Sash,War Sash,Plated Sash,Mesh Sash,Heavy Sash,Demonhide Sash,Dragonskin Sash,Studded Leather Sash,Hard Leather Sash,Leather Sash,Brightsilk Strap,Silk Strap,Wool Strap,Linen Strap,Strap";
  uint256 internal constant WAIST_ARMOR_LENGTH = 16;

  string internal constant FOOT_ARMOR = "Holy Greaves,Ornate Greaves,Impregnable Greaves,Chain Boots,Heavy Boots,Demonhide Boots,Dragonskin Boots,Studded Leather Boots,Hard Leather Boots,Leather Boots,Divine Slippers,Silk Slippers,Wool Shoes,Linen Shoes,Shoes";
  uint256 internal constant FOOT_ARMOR_LENGTH = 15;

  string internal constant HAND_ARMOR = "Holy Gauntlets,Ornate Gauntlets,Impregnable Gauntlets,Chain Gloves,Heavy Gloves,Demon's Hands,Dragonskin Gloves,Studded Leather Gloves,Hard Leather Gloves,Leather Gloves,Divine Gloves,Silk Gloves,Wool Gloves,Linen Gloves,Gloves";
  uint256 internal constant HAND_ARMOR_LENGTH = 15;

  string internal constant WEAPON2 = "Carnwennan,Devils Dagger,Diabolical Short Sword,Gastric Alleviation Speer,Feverish PickAxe,Dead Horsemans Pick,Everyday Mans Sledgehammer,Audacious Brides Hatchet,Pulmonary Mover Blade,Venomous Tipped Dagger,Impending Doom Laced Dagger";
  uint256 internal constant WEAPON2_LENGTH = 11;

  string internal constant WEAPON3 = "Sly Chicken Sickles,Futile Wooden War Club,Nimble bar stick,Infected Deer Horn Knives,Pompous Sober Mans Throwing Darts,Barbaric Hand Held Stone Club,Lucifers Sickle, Degen Ape";
  uint256 internal constant WEAPON3_LENGTH = 8;

  string internal constant SUFFIXES = "of Power,of Giants,of Titans,of Skill,of Perfection,of Brilliance,of Enlightenment,of Protection,of Anger,of Rage,of Fury,of Vitriol,of the Fox,of Detection,of Reflection,of the Twins";
  uint256 internal constant SUFFIXES_LENGTH = 16;

  string internal constant NAME_PREFIXES = "Agony,Apocalypse,Armageddon,Beast,Behemoth,Blight,Blood,Bramble,Brimstone,Brood,Carrion,Cataclysm,Chimeric,Corpse,Corruption,Damnation,Death,Demon,Dire,Dragon,Dread,Doom,Dusk,Eagle,Empyrean,Fate,Foe,Gale,Ghoul,Gloom,Glyph,Golem,Grim,Hate,Havoc,Honour,Horror,Hypnotic,Kraken,Loath,Maelstrom,Mind,Miracle,Morbid,Oblivion,Onslaught,Pain,Pandemonium,Phoenix,Plague,Rage,Rapture,Rune,Skull,Sol,Soul,Sorrow,Spirit,Storm,Tempest,Torment,Vengeance,Victory,Viper,Vortex,Woe,Wrath,Light's,Shimmering";
  uint256 internal constant NAME_PREFIXES_LENGTH = 69;

  string internal constant NAME_SUFFIXES = "Bane,Root,Crunch,Song,Roar,Grapple,Contraption,Shine,Bender,Shadow,Whisper,Scream,Growl,Rip,Peak,Form,Sun,Moon";
  uint256 internal constant NAME_SUFFIXES_LENGTH = 18;

  function getItem(
    uint256 rand,
    ListName listName
  )
    external
    pure
    returns (string memory)
  {
    if (listName == ListName.WEAPON) {
      return getItemFromCsv(WEAPONS, rand % WEAPONS_LENGTH);
    }
    if (listName == ListName.CHEST) {
      return getItemFromCsv(CHEST_ARMOR, rand % CHEST_ARMOR_LENGTH);
    }
    if (listName == ListName.HEAD) {
      return getItemFromCsv(HEAD_ARMOR, rand % HEAD_ARMOR_LENGTH);
    }
    if (listName == ListName.WAIST) {
      return getItemFromCsv(WAIST_ARMOR, rand % WAIST_ARMOR_LENGTH);
    }
    if (listName == ListName.FOOT) {
      return getItemFromCsv(FOOT_ARMOR, rand % FOOT_ARMOR_LENGTH);
    }
    if (listName == ListName.HAND) {
      return getItemFromCsv(HAND_ARMOR, rand % HAND_ARMOR_LENGTH);
    }
    if (listName == ListName.WEAPON2) {
      return getItemFromCsv(WEAPON2, rand % WEAPON2_LENGTH);
    }
    if (listName == ListName.WEAPON3) {
      return getItemFromCsv(WEAPON3, rand % WEAPON3_LENGTH);
    }
    if (listName == ListName.SUFFIX) {
      return getItemFromCsv(SUFFIXES, rand % SUFFIXES_LENGTH);
    }
    if (listName == ListName.NAME_PREFIX) {
      return getItemFromCsv(NAME_PREFIXES, rand % NAME_PREFIXES_LENGTH);
    }
    if (listName == ListName.NAME_SUFFIX) {
      return getItemFromCsv(NAME_SUFFIXES, rand % NAME_SUFFIXES_LENGTH);
    }
    revert("Invalid list name");
  }

  /**
   * @notice Convert an integer to a string.
   *
   * Inspired by OraclizeAPI's implementation (MIT license).
   * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
   */
  function toString(
    uint256 value
  )
    internal
    pure
    returns (string memory)
  {
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

  /**
   * @notice Read an item from a string of comma-separated values.
   *
   * Based on zefram.eth's implementation (MIT license).
   * https://etherscan.io/address/0xb9310af43f4763003f42661f6fc098428469adab#code
   */
  function getItemFromCsv(
    string memory str,
    uint256 index
  )
    internal
    pure
    returns (string memory)
  {
    strings.slice memory strSlice = str.toSlice();
    string memory separatorStr = ",";
    strings.slice memory separator = separatorStr.toSlice();
    strings.slice memory item;
    for (uint256 i = 0; i <= index; i++) {
      item = strSlice.split(separator);
    }
    return item.toString();
  }
}
