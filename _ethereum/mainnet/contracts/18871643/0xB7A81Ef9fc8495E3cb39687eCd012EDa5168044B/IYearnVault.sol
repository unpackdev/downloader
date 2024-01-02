// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IYearnVault {
    function pricePerShare() external view returns (uint256 price);

    function deposit(uint256 _amount) external returns (uint256);
}