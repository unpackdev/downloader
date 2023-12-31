// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IVeHakaDaoYieldDistributor {
    function notifyRewardAmount(uint256 amount) external;

    function yieldDuration() external view returns (uint256);
}
