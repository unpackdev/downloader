// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IFeeCollection {
  function collectManageFee(uint256 _amount) external;

  function collectPerformanceFee(address _strategy, uint256 _amount) external;
}
