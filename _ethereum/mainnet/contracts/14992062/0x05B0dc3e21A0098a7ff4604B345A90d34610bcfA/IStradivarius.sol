// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC721Enumerable.sol";

interface IStradivarius is IERC721Enumerable {
  function tokenURI(uint256 tokenId_) external view returns (string memory);

  function tokensOf(
    address owner_,
    uint256 offset_,
    uint256 limit_
  ) external view returns (uint256[] memory);

  function setBaseURI(string calldata baseUri_) external;

  function mint(address to_, uint256 tier_) external returns (uint256);
}
