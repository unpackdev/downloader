// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRewardCalculator {
    function rewardPerBlock() external view returns (uint256);
}
