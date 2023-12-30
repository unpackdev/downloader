// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface ILendingPoolCore {
    function approve(address spender, uint256 amount) external returns (bool);
}
