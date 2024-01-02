// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ISpotTradingRewardDistributorStorage {
    struct PeriodInfo {
        uint256 totalReward;
        // map trader address to her activity
        mapping(address => uint256) traderActivity;
        uint256 totalActivity;
    }

    function registry() external view returns (address);

    function dns() external view returns (address);

    function periodDuration() external view returns (uint256);

    function initialPeriodTimestamp() external view returns (uint256);

    function rewardPerPeriod() external view returns (uint256);

    function pmx() external view returns (address);

    function priceOracle() external view returns (address);

    function treasury() external view returns (address);

    function traderBalanceVault() external view returns (address payable);

    function undistributedPMX() external view returns (uint256);

    function periods(uint256 periodNumber) external view returns (uint256, uint256);
}
