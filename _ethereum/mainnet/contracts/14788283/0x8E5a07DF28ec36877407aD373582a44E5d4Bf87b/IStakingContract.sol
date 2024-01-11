// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IStakingContract {
    function depositWETHToStakingContract(uint256 _amount) external;
    function depositMFToStakingContract(uint256 _amountMF) external;
}