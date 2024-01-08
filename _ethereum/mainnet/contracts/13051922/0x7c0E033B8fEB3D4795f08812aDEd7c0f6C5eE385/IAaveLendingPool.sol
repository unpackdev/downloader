// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Address of Mainnet AAVE Lending Pool: 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9
interface IAaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;
}
