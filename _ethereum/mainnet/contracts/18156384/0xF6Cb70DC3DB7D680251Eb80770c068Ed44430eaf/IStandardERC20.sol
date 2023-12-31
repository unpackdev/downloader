// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStandardERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}
