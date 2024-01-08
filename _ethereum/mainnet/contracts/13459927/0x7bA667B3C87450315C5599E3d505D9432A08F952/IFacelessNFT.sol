// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IFacelessNFT {
  function totalSupply() external view returns (uint256);

  function mint(address to, uint256 tokenId) external;

  function ownerOf(uint256 tokenId) external view returns (address);

  function setApprovalForAll(address operator, bool _approved) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}
