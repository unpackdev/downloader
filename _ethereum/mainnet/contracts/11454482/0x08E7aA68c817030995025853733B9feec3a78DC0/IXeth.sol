// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.6.6;
// Copyright (C) udev 2020

import "./IERC20.sol";

interface IXeth is IERC20 {
    function deposit() external payable;
    function xlockerMint(uint wad, address dst) external;
    function withdraw(uint wad) external;
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event UlockerMint(uint wad, address dst);
}