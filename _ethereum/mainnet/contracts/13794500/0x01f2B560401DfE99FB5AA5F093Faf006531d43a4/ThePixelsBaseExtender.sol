// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixel {
  function pixelDNAExtensions(uint _tokenId) external view returns (uint256);
  function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}

contract ThePixelsBaseExtender {
  uint256 public decimal;
  address public pixelsAddress;

  event Extended(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  );

  constructor(uint256 _decimal) {
    decimal = _decimal;
  }

  function _setPixelsAddress(address _pixelsAddress) internal {
    pixelsAddress = _pixelsAddress;
  }

  function _getAddedExtension(uint256 extension, uint256 index) internal returns (uint256) {
    return extension + index * decimal;
  }

  function _rnd(address _owner, uint256 _tokenId, uint256 _dna, uint256 _dnaExtension) internal returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      _owner,
      _tokenId,
      _dna,
      _dnaExtension,
      block.timestamp
    )));
  }

  function _isSpecialEdition(uint256 _dna) internal view returns (bool) {
    if (_dna == 0 || _dna == 1 || _dna == 2 || _dna == 3 || _dna == 4) {
      return true;
    }
    return false;
  }
}
