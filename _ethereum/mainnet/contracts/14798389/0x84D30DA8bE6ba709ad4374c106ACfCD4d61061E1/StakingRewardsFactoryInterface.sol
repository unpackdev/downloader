// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface StakingRewardsFactoryInterface {
    function getStakingRewardsCount() external view returns (uint256);

    function getAllStakingRewards() external view returns (address[] memory);

    function getStakingRewards(address stakingToken)
        external
        view
        returns (address);
}
