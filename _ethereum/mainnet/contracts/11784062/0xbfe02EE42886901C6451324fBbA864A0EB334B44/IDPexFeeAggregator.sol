// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IDPexFeeAggregator {
    function isTokenHolder(address user) external view returns (bool);
    function feeTokens() external view returns (address[] memory);
    function isFeeToken(address token) external view returns (bool);
    function calculateFee(uint256 amount) external view returns (uint256 fee, uint256 amountLeft);
    function calculateFee(address token, uint256 amount) external view returns (uint256 fee, uint256 amountLeft);
    function getSnapshot(uint256 snapshotId) external view returns (uint256 time, uint256 totalPsi);
    function getSnapshotRewards(uint256 snapshotId, address user) external view returns (uint256 rewards);
    function getTotalRewards(address user) external view returns (uint256 rewards);
    function getUnclaimedRewards(address user) external view returns (uint256 rewards);
    function getClaimedRewards(address user) external view returns (uint256 rewards);

    function addTokenHolder(address user) external;
    function removeTokenHolder() external;
    function removeTokenHolder(address user) external;
    function addFeeToken(address token) external;
    function removeFeeToken(address token) external;
    function setDPexFee(uint256 fee) external;
    function addTokenFee(address token, uint256 fee) external;
    function takeSnapshotWithRewards(uint256 deadline) external;
    function claim() external;
}

