// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IScheduler {
  function schedule(address toAddress, bytes calldata callData, uint256[8] calldata _uintArgs) external payable returns (address);
  function computeEndowment(uint256 _bounty, uint256 _fee, uint256 _callGas, uint256 _callValue, uint256 _gasPrice) external view returns (uint256);
}
