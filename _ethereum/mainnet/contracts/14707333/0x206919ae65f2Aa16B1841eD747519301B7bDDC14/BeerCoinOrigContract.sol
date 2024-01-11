// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface BeerCoinOrigContract {
    function maximumCredit(address owner) external returns (uint);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address owner, address debtor) external returns (uint256 balance);
    function setMaximumCredit(uint credit) external;
    function approve(address spender, uint256 value) external returns (bool);
    function transferOtherFrom(address from, address to, address debtor, uint value) external returns (bool);
}