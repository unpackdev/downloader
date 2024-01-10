// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.4;

interface IRewardPool {
    function payTax(address account, uint256 burnAmount) external;
}