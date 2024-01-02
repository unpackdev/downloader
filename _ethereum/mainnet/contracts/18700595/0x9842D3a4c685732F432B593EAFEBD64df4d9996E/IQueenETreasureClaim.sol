// SPDX-License-Identifier: MIT

/// @title Interface for QueenE Treasure Claim

pragma solidity ^0.8.9;

interface IQueenETreasureClaim {
  struct sWhitelist {
    address wallet;
    uint256 value;
  }

  event ClaimPoolwithdraw(address indexed claimer, uint256 value);

  event ClaimPoolDeposit(address indexed benefactor, uint256 value);

  function depositToClaimPool(address _sender, uint256 amount) external payable;

  function withdrawnFromClaimPool() external;
}
