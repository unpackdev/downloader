// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IWeth9 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    /// @param wad The amount of wETH to withdraw into ETH
    function withdraw(uint256 wad) external;
}
