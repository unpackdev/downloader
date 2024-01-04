// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ILendingPoolV1 {
  function repay(
    address _reserve,
    uint256 _amount,
    address payable _onBehalfOf
  ) external payable;
}
