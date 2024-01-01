// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserve {
  function userReserve(address _account) external view returns (uint);
  function totalBankTypes() external view returns (uint);
  function getBankCountForType(address _account, uint _id) external view returns (uint count);
  function getRewards(address _account) external view returns (uint rewards);
  function claimBank(address _account, uint _id, uint _count) external returns (uint cost);
  function claimUpgrade(address _account, uint _id, uint _count) external returns (uint cost);
}