// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface WETH {

    function approve(address guy, uint256 wad) external returns (bool);

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;



    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}