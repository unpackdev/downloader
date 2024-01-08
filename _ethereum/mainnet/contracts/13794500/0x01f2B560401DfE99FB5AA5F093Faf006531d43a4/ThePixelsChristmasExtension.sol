// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./ThePixelsBaseExtender.sol";
import "./IThePixelsDNAUpdater.sol";

contract ThePixelsChristmasExtension is Ownable, ThePixelsBaseExtender, IThePixelsDNAUpdater {
  bool public isLive;
  constructor() ThePixelsBaseExtender(1)  {}

  function setIsLive(bool _isLive) external onlyOwner {
    isLive = _isLive;
  }

  function setPixelsAddress(address _pixelsAddress) external onlyOwner {
    _setPixelsAddress(_pixelsAddress);
  }

  function canUpdateDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external view override returns (bool) {
    return isLive;
  }

  function getUpdatedDNAExtension(
    address _owner,
    uint256 _tokenId,
    uint256 _dna,
    uint256 _dnaExtension
  ) external override returns (uint256) {
    require(isLive, "Extension is not live yet.");
    require(_dnaExtension == 0, "Already extended.");
    require(!_isSpecialEdition(_dna), "Can't extend special pixels");

    uint256 rnd = _rnd(_owner, _tokenId, _dna, _dnaExtension) % 100;
    uint256 variant;

    if (rnd >= 85) {
      variant = 3;
    }else if (rnd < 85 && rnd >= 50) {
      variant = 2;
    }else{
      variant = 1;
    }

    uint256 newExtension = _getAddedExtension(0, variant);
    emit Extended(_owner, _tokenId, _dna, newExtension);
    return newExtension;
  }

  function getExtendStatusOf(uint256[] memory tokens) public view returns (bool[] memory) {
    bool[] memory result = new bool[](tokens.length);
    for(uint256 i=0; i<tokens.length; i++) {
      uint256 dnaExtension = IThePixel(pixelsAddress).pixelDNAExtensions(tokens[i]);
      if (dnaExtension == 0) {
        result[i] = true;
      }
    }
    return result;
  }
}
