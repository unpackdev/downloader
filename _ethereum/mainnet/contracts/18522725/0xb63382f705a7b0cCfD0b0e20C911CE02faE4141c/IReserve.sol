// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserve {
  function totalBankTypes() external view returns (uint);
  function claimBank(address _account, uint _id, uint _count) external returns (uint cost);
  function claimUpgrade(address _account, uint _id, uint _count) external returns (uint cost);
}