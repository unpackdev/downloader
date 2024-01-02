// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function deposit(uint256 amount,uint256 minShares,address receiver) external returns (uint256 shares);

    function mint(uint256 amount, address account) external;
}
