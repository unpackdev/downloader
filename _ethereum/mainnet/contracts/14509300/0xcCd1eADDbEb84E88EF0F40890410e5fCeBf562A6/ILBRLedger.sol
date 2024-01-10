// SPDX-License-Identifier: MIT
// Author: LBR Ledger
// Developed by Max J. Rux
// Dev GitHub: @TheBigMort

pragma solidity ^0.8.9;

interface ILBRLedger {
  function mint(uint256 numMints) external payable;

  function contractURI() external view returns (string memory);

  function price() external view returns (uint256);

  function reserved() external view returns (uint256);

  function baseURI() external view returns (string memory);
}
