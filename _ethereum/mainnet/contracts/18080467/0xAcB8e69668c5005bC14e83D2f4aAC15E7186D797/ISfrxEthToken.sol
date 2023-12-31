// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ISfrxEthToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function decimals() external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function rewardsCycleEnd() external view returns (uint32);

    function syncRewards() external;

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}
