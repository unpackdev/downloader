// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

library ClayLibrary {
  uint256 public constant SEED = 144261992486;
  
  struct Traits {
    uint8 base;
    uint8 ore;
    uint8 largeOre;
    uint8 bgColor;
  }

  function getTiers() internal pure returns (uint16[][4] memory) {
    uint16[][4] memory TIERS = [
      new uint16[](4),
      new uint16[](9),
      new uint16[](2),
      new uint16[](6)
    ];

    //Base
    TIERS[0][0] = 4000;
    TIERS[0][1] = 3000;
    TIERS[0][2] = 2000;
    TIERS[0][3] = 1000;

    //Ore
    TIERS[1][0] = 5000;
    TIERS[1][1] = 1500;
    TIERS[1][2] = 1500;
    TIERS[1][3] = 750;
    TIERS[1][4] = 750;
    TIERS[1][5] = 200;
    TIERS[1][6] = 200;
    TIERS[1][7] = 90;
    TIERS[1][8] = 10;

    //LargeOre
    TIERS[2][0] = 7500;
    TIERS[2][1] = 2500;

    //BgColor
    TIERS[3][0] = 2000;
    TIERS[3][1] = 2000;
    TIERS[3][2] = 1500;
    TIERS[3][3] = 1500;
    TIERS[3][4] = 1500;
    TIERS[3][5] = 1500;

    return TIERS;
  }

  function getBaseMultiplier(uint index) internal pure returns (uint256) {
    uint8[4] memory baseTiers = [
      10,
      20,
      30,
      40
    ];

    return uint256(baseTiers[index]);
  }

  function getOreMultiplier(uint index) internal pure returns (uint256) {
     uint16[9] memory oreTiers = [
      1000,
      2500,
      3000,
      3500,
      4000,
      1500,
      2000,
      6000,
      10000
    ];

    return uint256(oreTiers[index]);
  }

  function getTraitIndex(string memory _hash, uint index) internal pure returns (uint8) {
    return parseInt(substring(_hash, index, index + 1));
  }

  function getTraits(uint256 _t) internal pure returns (Traits memory) {
    string memory _hash = generateMetadataHash(_t);
    uint8 baseIndex = getTraitIndex(_hash, 0);
    uint8 oreIndex = getTraitIndex(_hash, 1);
    uint8 largeOreIndex = getTraitIndex(_hash, 2);
    uint8 bgColorIndex = getTraitIndex(_hash, 3);
    return Traits(baseIndex, oreIndex, largeOreIndex, bgColorIndex);
  }

    function generateMetadataHash(uint256 _t)
        internal
        pure
        returns (string memory)
    {
      string memory currentHash = "";
      for (uint8 i = 0; i < 4; i++) {
          uint16 _randinput = uint16(
              uint256(keccak256(abi.encodePacked(_t, SEED))) % 10000
          );

          currentHash = string(
              abi.encodePacked(currentHash, rarityGen(_randinput, i))
          );
      }

      return currentHash;
    }

    function rarityGen(
        uint256 _randinput,
        uint8 _rarityTier
    ) internal pure returns (string memory) {
      uint16[][4] memory TIERS = getTiers();
      uint16 currentLowerBound = 0;
      for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
          uint16 thisPercentage = TIERS[_rarityTier][i];
          if (
              _randinput >= currentLowerBound &&
              _randinput < currentLowerBound + thisPercentage
          ) return toString(i);
          currentLowerBound = currentLowerBound + thisPercentage;
      }

      revert();
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function stringLength(
        string memory str
    ) internal pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        return strBytes.length;
    }

    function isNotEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length > 0;
    }
}
