//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INFT {
  function tokenIdMax() external view returns (uint16);

  function currentTokenId() external view returns (uint16);

  function mint(address to) external;
}
