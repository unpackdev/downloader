// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaker {
  function balanceOfPool(address _gauge) external view returns(uint256);
}