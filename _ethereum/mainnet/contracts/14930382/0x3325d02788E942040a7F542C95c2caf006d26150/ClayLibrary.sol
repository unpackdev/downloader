// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

library ClayLibrary {
  uint256 public constant SEED = 144261992486;

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

  function getUpgradeCost(uint index) internal pure returns (uint256) {
    uint16[4] memory baseTiers = [
      50,
      100,
      250,
      400
    ];

    return uint256(baseTiers[index]);
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
