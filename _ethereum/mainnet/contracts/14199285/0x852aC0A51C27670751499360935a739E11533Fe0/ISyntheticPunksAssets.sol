//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ISyntheticPunksAssets {
  function spritesheetImageData() external view returns (string memory);
  function spritesheetRanges() external view returns (uint256[4][9] memory);
  function attributesContentURI() external view returns (string memory);
}