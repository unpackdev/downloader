// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniFarm {
    function deposit(uint256 amount, address receiver) external;
}
