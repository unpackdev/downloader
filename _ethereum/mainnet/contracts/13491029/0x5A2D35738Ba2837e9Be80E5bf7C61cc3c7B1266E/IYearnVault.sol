// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IYearnVault {
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256 shares);

    function withdraw(uint256 shares) external;

    function pricePerShare() external view returns (uint256);
}
