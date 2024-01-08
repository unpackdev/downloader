// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

interface IStakingPool {
    function addReward(uint256 amount) external;
    function transferOwnership(address newOwner) external;
}