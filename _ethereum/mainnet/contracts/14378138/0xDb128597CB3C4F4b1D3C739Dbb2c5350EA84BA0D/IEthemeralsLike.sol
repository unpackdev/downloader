// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
interface IEthemeralsLike {
  function maxMeralIndex() external view returns (uint256);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 _tokenId) external view returns (address);
  function transferOwnership(address newOwner) external;
  function mintMeralsAdmin(address recipient, uint256 _amount) external;
}