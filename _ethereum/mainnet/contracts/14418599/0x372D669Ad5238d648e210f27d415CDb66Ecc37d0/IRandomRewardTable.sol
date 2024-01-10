// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRandomRewardTable {
    function rewardRandomOne(address _to, uint256 _rand) external;
}
