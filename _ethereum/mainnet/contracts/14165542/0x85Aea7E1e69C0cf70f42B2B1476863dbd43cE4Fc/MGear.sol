// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";

import "./Stats.sol";
import "./IRenderer.sol";
import "./IMGear.sol";
import "./IMineablePunks.sol";
import "./IMineableWords.sol";

contract MGear is ERC721Enumerable, Ownable {
  uint8 NORMAL;
  uint8 SOLID = 1;
  uint8 NOTEWORTHY = 2;
  uint8 EXTRAORDINARY = 3;
  uint8 FABLED = 4;
  uint8 UNREAL = 5;

  uint16 minedCount;

  uint8 unrealUpgrades;
  uint8 fabledUpgrades;
  uint8 extraordinaryUpgrades;

  IMineablePunks public mineablePunks;
  IMineableWords public mineableWords;
  IMGear public mgearRenderer;

  uint256[] public tokenIdToMGear;

  mapping(uint256 => bool) public transmuted;
  mapping(uint16 => bool) public inscribed;

  uint256[3] public rarityToDifficulties;

  uint8[3][3] public rarityToUpgradeRoll;
  uint88[6] rarityNames;
  uint8[3] public mpunkRolls;

  constructor(
    IMineablePunks _mineablePunks,
    IMineableWords _mineableWords,
    IMGear _mgear,
    uint256 normal,
    uint256 solid,
    uint256 noteworthy
  ) ERC721("MineableGear", "MGEAR") Ownable() {
    mineablePunks = _mineablePunks;
    mineableWords = _mineableWords;
    mgearRenderer = _mgear;

    rarityToDifficulties[NORMAL] = normal;
    rarityToDifficulties[SOLID] = solid;
    rarityToDifficulties[NOTEWORTHY] = noteworthy;

    rarityToUpgradeRoll[0] = [1, 4, 8];
    rarityToUpgradeRoll[1] = [2, 8, 16];
    rarityToUpgradeRoll[2] = [4, 16, 32];

    mpunkRolls[0] = EXTRAORDINARY;
    mpunkRolls[1] = FABLED;
    mpunkRolls[2] = UNREAL;

    rarityNames[0] = 0x056ba2c02c000000000000;
    rarityNames[1] = 0x0493968180000000000000;
    rarityNames[2] = 0x096ba64b3a333e00000000;
    rarityNames[3] = 0x0c25e7103a2343411c0000;
    rarityNames[4] = 0x052802b20c000000000000;
    rarityNames[5] = 0x05a362402c000000000000;
  }

  fallback() external payable {}

  receive() external payable {}

  function withdraw(uint256 amount) external onlyOwner {
    payable(Ownable.owner()).transfer(amount);
  }

  function toMWordEncoding(uint64 abbr) internal pure returns (uint88) {
    return uint88(abbr) << 24;
  }

  function encodeNonce(address sender, uint96 nonce) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(uint160(sender), nonce)));
  }

  function encodeMgear(
    uint256 mgear,
    uint8 rarity,
    uint16 mwordIndex,
    uint8 nameFormat
  ) internal returns (uint256) {
    if (mwordIndex > 0) {
      require(
        mineableWords.ownerOf(mineableWords.tokenByIndex(mwordIndex - 1)) == msg.sender,
        "own"
      );
      require(!inscribed[mwordIndex], "alr");
    }
    require(nameFormat < 2, "inv");

    if (mwordIndex > 0) {
      inscribed[mwordIndex] = true;
    }

    return
      (mgear & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFE0007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8) +
      rarity +
      (uint256(mwordIndex) << 127) +
      (uint256(nameFormat) << 140);
  }

  function upgradeAndEncode(
    uint256 mgear,
    uint8 rarity,
    uint16 mwordIndex,
    uint8 nameFormat
  ) internal returns (uint256) {
    if (rarity < 3) {
      uint8 upgradeRoll = uint8(mgear >> 9) & 0xff;
      if (upgradeRoll < rarityToUpgradeRoll[rarity][0] && unrealUpgrades < 16) {
        unrealUpgrades = unrealUpgrades + 1;
        return encodeMgear(mgear, UNREAL, mwordIndex, nameFormat);
      }
      if (upgradeRoll < rarityToUpgradeRoll[rarity][1] && fabledUpgrades < 64) {
        fabledUpgrades = fabledUpgrades + 1;
        return encodeMgear(mgear, FABLED, mwordIndex, nameFormat);
      }
      if (upgradeRoll < rarityToUpgradeRoll[rarity][2] && extraordinaryUpgrades < 128) {
        extraordinaryUpgrades = extraordinaryUpgrades + 1;
        return encodeMgear(mgear, EXTRAORDINARY, mwordIndex, nameFormat);
      }
    }
    return encodeMgear(mgear, rarity, mwordIndex, nameFormat);
  }

  function getTransmutationRarity(uint256 hashed, uint256 mpunk) public view returns (uint8) {
    uint8 base = uint8((mineablePunks.punkIdToAssets(mpunk) >> 88) & 0xf);
    //rare punk roll
    if (base == 11) return UNREAL;
    if (base == 10) return mpunkRolls[uint8(hashed % 2)];
    if (base == 9) return mpunkRolls[uint8(hashed % 3)];

    //normal punk roll out of 64
    uint8 roll = uint8(hashed & 0x3f);
    if (roll < 1) return UNREAL;
    if (roll < 5) return FABLED;
    if (roll < 13) return EXTRAORDINARY;
    if (roll < 37) return NOTEWORTHY;
    if (roll < 52) return SOLID;
    return NORMAL;
  }

  function renderData(uint256 mgear) public view returns (string memory data) {
    return mgearRenderer.renderData(mgear);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(ERC721._exists(tokenId), "not found");
    return mgearRenderer.renderData(tokenIdToMGear[tokenId]);
  }

  function rename(
    uint256 tokenId,
    uint16 mwordIndex,
    uint8 nameFormat
  ) external payable {
    require(ERC721.ownerOf(tokenId) == msg.sender, "own");
    if (mwordIndex > 0) {
      require(
        mineableWords.ownerOf(mineableWords.tokenByIndex(mwordIndex - 1)) == msg.sender,
        "own"
      );
    }
    require(msg.value >= 5000000000000000, "fee");
    require(!inscribed[mwordIndex], "alr");

    uint256 mgear = tokenIdToMGear[tokenId];
    inscribed[uint16(mgear >> 127) & 0x1fff] = false;
    inscribed[mwordIndex] = true;
    tokenIdToMGear[tokenId] =
      (mgear & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFE0007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) +
      (uint256(mwordIndex) << 127) +
      (uint256(nameFormat) << 140);
  }

  function mint(
    uint96 nonce,
    uint8 rarity,
    uint16 mwordIndex,
    uint8 nameFormat
  ) external payable {
    require(rarity >= NORMAL && rarity <= NOTEWORTHY, "inv");
    require(minedCount < 2048, "lim");
    uint256 hashed = encodeNonce(msg.sender, nonce);
    require(hashed < rarityToDifficulties[rarity], "dif");
    require(msg.value >= 20000000000000000, "fee");

    uint256 tokenId = tokenIdToMGear.length;
    tokenIdToMGear.push(upgradeAndEncode(hashed, rarity, mwordIndex, nameFormat));

    ERC721._safeMint(msg.sender, tokenId);

    minedCount = minedCount + 1;
  }

  function transmute(
    uint256 mpunk,
    uint16 mwordIndex,
    uint8 nameFormat
  ) external payable {
    require(minedCount == 2048, "lock");
    require(mineablePunks.ownerOf(mpunk) == msg.sender, "own");
    require(!transmuted[mpunk], "alr");
    require(msg.value >= 10000000000000000, "fee");

    uint256 hashed = encodeNonce(address(mineablePunks), uint96(mpunk));

    uint256 tokenId = tokenIdToMGear.length;
    tokenIdToMGear.push(
      encodeMgear(hashed, getTransmutationRarity(hashed, mpunk), mwordIndex, nameFormat)
    );
    ERC721._safeMint(msg.sender, tokenId);
    transmuted[mpunk] = true;
  }
}
