//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";

abstract contract LootContract {
  function ownerOf(uint256 tokenId) public view virtual returns (address);
}

abstract contract MLootContract {
  function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract LootItems is Ownable, ERC721, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdTracker;
  LootContract private loot;
  MLootContract private mLoot;

  enum Category {
    weapon,
    chest,
    head,
    waist,
    foot,
    hand,
    neck,
    ring
  }

  struct LootAvailable {
    uint256 lootTokenId;
    bool available;
  }

  mapping(uint256 => uint256) public lootIdToLastRedeemed;
  mapping(uint256 => uint256) public lootIdToNumberTimesRedeemed;
  mapping(uint256 => uint256) public itemIdToCategory;
  mapping(uint256 => uint256) public itemIdToLootId;

  uint256 public a;
  uint256 public b;
  uint256 public x;
  uint256 public y;

  uint256 public totalSupply;
  bool public isMLootUnbundleSupported = true;

  /**
   * @dev We are bringing in the logic from ERC721Enumerable that
   * we want in order to optimize gas usage.
   */
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  constructor(address lootAddress, address mLootAddress)
    ERC721("LootItems", "ITEMS")
  {
    loot = LootContract(lootAddress);
    mLoot = MLootContract(mLootAddress);
    _tokenIdTracker.increment();
    a = 0;
    b = 4032000;
    x = 0;
    y = 40320;
    totalSupply = 0;
  }

  function getAllLootAvailability(uint256[] memory lootTokenIds)
    public
    view
    returns (LootAvailable[] memory)
  {
    LootAvailable[] memory availability = new LootAvailable[](
      lootTokenIds.length
    );
    uint256 blockNumber = block.number;
    for (uint256 i = 0; i < lootTokenIds.length; i++) {
      uint256 lootTokenId = lootTokenIds[i];
      uint256 lastRedeemedBlock = lootIdToLastRedeemed[lootTokenId];
      uint256 numberTimesRedeemed = lootIdToNumberTimesRedeemed[lootTokenId];
      bool available = true;

      if (lastRedeemedBlock != 0) {
        // check whether it's off cooldown
        uint256 cooldown = getCooldown(
          numberTimesRedeemed,
          isOriginalLoot(lootTokenId)
        );
        if (blockNumber - lastRedeemedBlock < cooldown) {
          available = false;
        }
      }
      availability[i] = LootAvailable(lootTokenId, available);
    }
    return availability;
  }

  function getAllLootItems(uint256[] memory lootTokenIds) public nonReentrant {
    for (uint256 i = 0; i < lootTokenIds.length; i++) {
      getLootItems(lootTokenIds[i]);
    }
  }

  function isOriginalLoot(uint256 lootId) internal pure returns (bool) {
    return lootId > 0 && lootId < 8001;
  }

  function getLootItems(uint256 lootTokenId) public nonReentrant {
    require(lootTokenId > 0, "Token ID invalid");
    if (isOriginalLoot(lootTokenId)) {
      require(loot.ownerOf(lootTokenId) == msg.sender, "Must own loot");
    } else {
      require(isMLootUnbundleSupported, "MLoot unbundle not yet supported.");
      require(mLoot.ownerOf(lootTokenId) == msg.sender, "Must own loot");
    }
    uint256 lastRedeemedBlock = lootIdToLastRedeemed[lootTokenId];
    uint256 blockNumber = block.number;
    uint256 numberTimesRedeemed = lootIdToNumberTimesRedeemed[lootTokenId];
    if (lastRedeemedBlock != 0) {
      // check whether it's off cooldown
      uint256 cooldown = getCooldown(
        numberTimesRedeemed,
        isOriginalLoot(lootTokenId)
      );
      require(
        blockNumber - lastRedeemedBlock >= cooldown,
        "Loot not off cooldown"
      );
    }

    uint256 newTokenId = _tokenIdTracker.current();
    _safeMintBatch(8, msg.sender, newTokenId);

    unbundle(Category.weapon, lootTokenId);
    unbundle(Category.chest, lootTokenId);
    unbundle(Category.head, lootTokenId);
    unbundle(Category.waist, lootTokenId);
    unbundle(Category.foot, lootTokenId);
    unbundle(Category.hand, lootTokenId);
    unbundle(Category.neck, lootTokenId);
    unbundle(Category.ring, lootTokenId);

    lootIdToNumberTimesRedeemed[lootTokenId] = numberTimesRedeemed + 1;
    lootIdToLastRedeemed[lootTokenId] = blockNumber;
    totalSupply = totalSupply + 8;
  }

  function unbundle(Category category, uint256 lootTokenId) internal {
    uint256 newTokenId = _tokenIdTracker.current();
    // _safeMint(msg.sender, newTokenId);
    _tokenIdTracker.increment();

    itemIdToCategory[newTokenId] = uint256(category);
    itemIdToLootId[newTokenId] = lootTokenId;
  }

  function getCooldown(uint256 numberTimesRedeemed, bool isSourceOriginalRoot)
    public
    view
    returns (uint256)
  {
    if (isSourceOriginalRoot) {
      return x * numberTimesRedeemed + y;
    }
    return a * numberTimesRedeemed + b;
  }

  function modifyCooldown(
    uint256 updatedA,
    uint256 updatedB,
    uint256 updatedX,
    uint256 updatedY
  ) external onlyOwner {
    a = updatedA;
    b = updatedB;
    x = updatedX;
    y = updatedY;
  }

  // loot logic
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

  function getWeapon(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "WEAPON", weapons, greatnessSeparator);
  }

  function getChest(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "CHEST", chestArmor, greatnessSeparator);
  }

  function getHead(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "HEAD", headArmor, greatnessSeparator);
  }

  function getWaist(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "WAIST", waistArmor, greatnessSeparator);
  }

  function getFoot(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "FOOT", footArmor, greatnessSeparator);
  }

  function getHand(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "HAND", handArmor, greatnessSeparator);
  }

  function getNeck(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "NECK", necklaces, greatnessSeparator);
  }

  function getRing(uint256 tokenId, string memory greatnessSeparator) internal view returns (string memory) {
    return pluck(tokenId, "RING", rings, greatnessSeparator);
  }

  function pluck(
    uint256 tokenId,
    string memory keyPrefix,
    string[] memory sourceArray,
    string memory greatnessSeparator
  ) internal view returns (string memory) {
    uint256 rand = random(
      string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
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
          abi.encodePacked(greatnessSeparator, name[0], " ", name[1], greatnessSeparator, ' ', output)
        );
      } else {
        output = string(
          abi.encodePacked(greatnessSeparator, name[0], " ", name[1], greatnessSeparator, ' ', output, " +1")
        );
      }
    }
    return output;
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function getName(uint256 category, uint256 lootTokenId, string memory greatnessSeparator)
    internal
    view
    returns (string memory)
  {
    if (category == 0) {
      return getWeapon(lootTokenId, greatnessSeparator);
    } else if (category == 1) {
      return getChest(lootTokenId, greatnessSeparator);
    } else if (category == 2) {
      return getHead(lootTokenId, greatnessSeparator);
    } else if (category == 3) {
      return getWaist(lootTokenId, greatnessSeparator);
    } else if (category == 4) {
      return getFoot(lootTokenId, greatnessSeparator);
    } else if (category == 5) {
      return getHand(lootTokenId, greatnessSeparator);
    } else if (category == 6) {
      return getNeck(lootTokenId, greatnessSeparator);
    } else {
      return getRing(lootTokenId, greatnessSeparator);
    }
  }

  function convertToCategoryName(uint256 category)
    internal
    pure
    returns (string memory)
  {
    if (category == 0) {
      return "Weapon";
    } else if (category == 1) {
      return "Chest";
    } else if (category == 2) {
      return "Head";
    } else if (category == 3) {
      return "Waist";
    } else if (category == 4) {
      return "Foot";
    } else if (category == 5) {
      return "Hand";
    } else if (category == 6) {
      return "Neck";
    } else {
      return "Ring";
    }
  }

  function enableMLootUnbundle() public onlyOwner {
    isMLootUnbundleSupported = true;
  }

  function disableMLootUnbundle() public onlyOwner {
    isMLootUnbundleSupported = false;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    if (tokenId == 0 || tokenId > totalSupply) {
      return "";
    }
    uint256 category = itemIdToCategory[tokenId];
    uint256 lootId = itemIdToLootId[tokenId];
    string memory name = getName(category, lootId, '"');
    bool originalLoot = isOriginalLoot(lootId);

    string memory attribute = string(
      abi.encodePacked(
        '{"trait_type": "',
        convertToCategoryName(category),
        '", "value": "',
        getName(category, lootId, "'"),
        '"}'
      )
    );

    string[17] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
    parts[1] = name;
    parts[2] = "</text></svg>";
    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2])
    );
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            getName(category, lootId, "'"),
            '", "description": "Loot Items are individual items from a Loot Bag represented as ERC721 tokens. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot Items in any way you want.", "attributes": [',
            attribute,
            '], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );

    if (originalLoot) {
      json = Base64.encode(
        bytes(
          string(
            abi.encodePacked(
              '{"name": "',
              getName(category, lootId, "'"),
              '", "description": "Loot Items are individual items from a Loot Bag or mLoot Bag represented as ERC721 tokens. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot Items in any way you want.", "attributes": [',
              attribute,
              ",",
              '{"trait_type": "Edition", "value": "Original"}',
              '], "image": "data:image/svg+xml;base64,',
              Base64.encode(bytes(output)),
              '"}'
            )
          )
        )
      );
    }

    output = string(abi.encodePacked("data:application/json;base64,", json));
    return output;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() public payable onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0) && from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0) && to != from) {
      _addTokenToOwnerEnumeration(to, tokenId, 1);
    }
  }

  function _batchBeforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 numTokens
  ) internal virtual override(ERC721) {
    for (uint256 i = 0; i < numTokens; i++) {
      super._beforeTokenTransfer(from, to, tokenId + i);

      if (from != address(0) && from != to) {
        _removeTokenFromOwnerEnumeration(from, tokenId + i);
      }
    }

    if (to != address(0) && to != from) {
      _addTokenToOwnerEnumeration(to, tokenId, numTokens);
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev We are bringing in the logic from ERC721Enumerable that
   * we want in order to optimize gas usage.
   */

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    returns (uint256)
  {
    require(
      index < balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param startTokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(
    address to,
    uint256 startTokenId,
    uint256 numOfTokens
  ) private {
    uint256 length = ERC721.balanceOf(to);

    for (uint256 i = 0; i < numOfTokens; i++) {
      _ownedTokens[to][length + i] = startTokenId + i;
      _ownedTokensIndex[startTokenId + i] = length + i;
    }
  }

  /**
   * @dev We are bringing in the logic from ERC721Burnable.
   */
  function burn(uint256 tokenId) public virtual {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721Burnable: caller is not owner nor approved"
    );
    _burn(tokenId);
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
