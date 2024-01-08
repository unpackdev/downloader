// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ColorStrings {
  bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

  function toHexColorString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '00';
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexColorString(value, length);
  }

  function toHexColorString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length);
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i - 2] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}
