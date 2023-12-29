// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISeed {
  function totalSupply() external returns (uint256);

  function mint(address to, uint256 tokenId) external;

  function setMaxSupply(uint256 maxSupply) external;

  function setSCR(address scr) external;

  function setBaseURI(string memory baseURI) external;

  function setURILevelRange(uint256[] calldata uriLevelRanges) external;

  function pause() external;

  function unpause() external;

  function transferOwnership(address newOwner) external;
}
