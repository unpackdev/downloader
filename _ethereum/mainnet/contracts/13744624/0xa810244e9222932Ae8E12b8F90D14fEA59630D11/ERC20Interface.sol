// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

interface ERC20 {
    function approve(address usr, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}