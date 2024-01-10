// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IComptroller {
    function cTokensByUnderlying(address) external view returns (address cToken);

    function rewardsDistributors(uint256 index) external view returns (address);

    function markets(address market) external view returns (bool isListed, uint256 collateralFactorMantissa);
}

interface IRariRewardDistributor {
    function rewardToken() external view returns (address);

    function compAccrued(address holder) external view returns (uint256);

    function claimRewards(address holder) external;

    function getAllMarkets() external view returns (address[] calldata);
}
