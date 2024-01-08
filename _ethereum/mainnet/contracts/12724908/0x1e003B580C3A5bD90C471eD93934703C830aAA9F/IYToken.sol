// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IYToken {
    function balanceOf(address user) external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit() external returns (uint256);

    function withdraw(uint256 shares) external returns (uint256);

    function token() external returns (address);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);

    function decimals() external view returns (uint8);

    function withdrawalQueue(uint256 index) external view returns (address);

    function maxAvailableShares() external view returns (uint256);
}
