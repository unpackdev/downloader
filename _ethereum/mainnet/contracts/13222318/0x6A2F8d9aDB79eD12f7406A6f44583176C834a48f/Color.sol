//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Color {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  function generateColorValue(string memory prefix, uint256 tokenId)
    private
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(prefix, tokenId))) % 4096;
  }

  function getColorHexCode(uint256 value)
    internal
    pure
    returns (string memory)
  {
    uint16 red = uint16((value >> 8) & 0xf);
    uint16 green = uint16((value >> 4) & 0xf);
    uint16 blue = uint16(value & 0xf);

    bytes memory buffer = new bytes(7);

    buffer[0] = "#";
    buffer[1] = _HEX_SYMBOLS[red];
    buffer[2] = _HEX_SYMBOLS[red];
    buffer[3] = _HEX_SYMBOLS[green];
    buffer[4] = _HEX_SYMBOLS[green];
    buffer[5] = _HEX_SYMBOLS[blue];
    buffer[6] = _HEX_SYMBOLS[blue];

    return string(buffer);
  }

  function generateColorHexCode(string memory prefix, uint256 tokenId)
    internal
    pure
    returns (string memory)
  {
    uint256 colorValue = generateColorValue(prefix, tokenId);
    return getColorHexCode(colorValue);
  }
}
