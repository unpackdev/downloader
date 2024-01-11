// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IDssVest {
  function vest(uint256 _id) external;

  function vest(uint256 _id, uint256 _maxAmt) external;

  struct Award {
    address usr; // Vesting recipient
    uint48 bgn; // Start of vesting period  [timestamp]
    uint48 clf; // The cliff date           [timestamp]
    uint48 fin; // End of vesting period    [timestamp]
    address mgr; // A manager address that can yank
    uint8 res; // Restricted
    uint128 tot; // Total reward amount
    uint128 rxd; // Amount of vest claimed
  }

  function awards(uint256 _id)
    external
    view
    returns (
      address usr, // Vesting recipient
      uint48 bgn, // Start of vesting period  [timestamp]
      uint48 clf, // The cliff date           [timestamp]
      uint48 fin, // End of vesting period    [timestamp]
      address mgr, // A manager address that can yank
      uint8 res, // Restricted
      uint128 tot, // Total reward amount
      uint128 rxd // Amount of vest claimed
    );
}
