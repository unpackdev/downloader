//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IVotersInvestmentDispenser {
  function deposit(uint snapshotId, uint amount) external;
}