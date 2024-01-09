// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";

import "./Stats.sol";
import "./IRenderer.sol";
import "./IMineablePunks.sol";
import "./IMineableWords.sol";
import "./EncodeLibrary.sol";

contract MGear is ERC721Enumerable, Ownable, Stats {
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
  IRenderer public renderer;

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
    IRenderer _renderer,
    uint256 normal,
    uint256 solid,
    uint256 noteworthy
  ) ERC721("MineableGear", "MGEAR") Ownable() {
    mineablePunks = _mineablePunks;
    mineableWords = _mineableWords;
    renderer = _renderer;

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
    uint8 roll = uint8(base & 0x3f);
    if (roll < 1) return UNREAL;
    if (roll < 5) return FABLED;
    if (roll < 13) return EXTRAORDINARY;
    if (roll < 37) return NOTEWORTHY;
    if (roll < 52) return SOLID;
    return NORMAL;
  }

  function getMGearName(uint256 mgear) public view returns (string memory name) {
    uint256 mwordIndex = (mgear >> 127) & 0x1fff;
    uint88 gearName = toMWordEncoding(renderer.getGearName(mgear));

    if (mwordIndex > 0) {
      uint88 mword = uint88(mineableWords.tokenByIndex(mwordIndex - 1));
      uint8 useOf = uint8(mgear >> 140) & 0x1;
      if (useOf > 0) {
        return
          string(
            abi.encodePacked(
              mineableWords.decodeMword((rarityNames[renderer.getRarity(mgear)])),
              " ",
              mineableWords.decodeMword(gearName),
              " of ",
              mineableWords.decodeMword(mword)
            )
          );
      } else {
        return
          string(
            abi.encodePacked(
              mineableWords.decodeMword((rarityNames[renderer.getRarity(mgear)])),
              " ",
              mineableWords.decodeMword(mword),
              " ",
              mineableWords.decodeMword(gearName)
            )
          );
      }
    }
    return
      string(
        abi.encodePacked(
          mineableWords.decodeMword((rarityNames[renderer.getRarity(mgear)])),
          " ",
          mineableWords.decodeMword(gearName)
        )
      );
  }

  function renderData(uint256 mgear) public view returns (string memory data) {
    uint64[3] memory stats;
    stats[0] = getMajorType(mgear);
    stats[1] = getMinorType1(mgear);
    stats[2] = getMinorType2(mgear);

    uint8[3] memory values;
    values[0] = getMajorValue(mgear);
    values[1] = getMinorValue1(mgear);
    values[2] = getMinorValue2(mgear);

    //coalesce if the same
    if (stats[1] == stats[0]) {
      values[0] = values[0] + values[1];
      values[1] = 0;
      stats[1] = 0;
    }

    if (stats[2] == stats[0]) {
      values[0] = values[0] + values[2];
      values[2] = 0;
      stats[2] = 0;
    }

    if (stats[2] == stats[1]) {
      values[1] = values[1] + values[2];
      values[2] = 0;
      stats[2] = 0;
    }

    string memory traits = string(
      abi.encodePacked(
        EncodeLibrary.makeTrait(
          "rarity",
          mineableWords.decodeMword(rarityNames[(mgear & 0x7) % 6])
        ),
        ",",
        EncodeLibrary.makeTrait(
          "gear-type",
          mineableWords.decodeMword(toMWordEncoding(renderer.getGearName(mgear)))
        ),
        ",",
        EncodeLibrary.makeNumberTrait(
          mineableWords.decodeMword(toMWordEncoding(stats[0])),
          values[0]
        )
      )
    );

    if (stats[1] > 0 && values[1] > 0) {
      traits = string(
        abi.encodePacked(
          traits,
          ",",
          EncodeLibrary.makeNumberTrait(
            mineableWords.decodeMword(toMWordEncoding(stats[1])),
            values[1]
          )
        )
      );
    }

    if (stats[2] > 0 && values[2] > 0) {
      traits = string(
        abi.encodePacked(
          traits,
          ",",
          EncodeLibrary.makeNumberTrait(
            mineableWords.decodeMword(toMWordEncoding(stats[2])),
            values[2]
          )
        )
      );
    }

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          EncodeLibrary.encode(
            bytes(
              abi.encodePacked(
                '{"name": "',
                getMGearName(mgear),
                '", "description": "on-chain gear obtained through mining.", "image": "data:image/svg+xml;base64,',
                EncodeLibrary.encode(bytes(renderer.render(mgear))),
                '", "attributes": [',
                traits,
                "] }"
              )
            )
          )
        )
      );
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(ERC721._exists(tokenId), "not found");
    return renderData(tokenIdToMGear[tokenId]);
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
