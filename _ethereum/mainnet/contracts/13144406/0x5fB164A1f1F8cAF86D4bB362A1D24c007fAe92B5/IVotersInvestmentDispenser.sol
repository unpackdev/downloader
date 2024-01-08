//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotersInvestmentDispenser {
  function deposit(uint snapshotId, uint amount) external;
}
