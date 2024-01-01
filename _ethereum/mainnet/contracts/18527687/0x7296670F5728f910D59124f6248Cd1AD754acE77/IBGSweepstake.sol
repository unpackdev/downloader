// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBGSweepstake {
      function enterSweepstakeAfterTicketsBurnt(address playerAddress, uint256 numberOfEntries) external;
}