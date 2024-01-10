// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICheque {
  function setBaseURI(string memory uri) external;

  function mintedCount() external view returns (uint256);
}
