// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IYVault {
    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function lockedProfitDegradation() external view returns (uint256);

    function lockedProfit() external view returns (uint256);

    function deposit(uint256) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function withdrawalQueue(uint256) external returns (address);

    function balanceOf(address user) external view returns (uint256);
}
