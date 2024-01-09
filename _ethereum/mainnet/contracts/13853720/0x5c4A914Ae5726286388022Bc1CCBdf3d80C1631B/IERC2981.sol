// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IERC2981 {
  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}