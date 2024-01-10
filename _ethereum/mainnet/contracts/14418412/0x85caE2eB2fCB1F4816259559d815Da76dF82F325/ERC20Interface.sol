// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ERC20Interface {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
