// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICToken {
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function underlying() external view returns (address);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function comptroller() external view returns (address);
}
