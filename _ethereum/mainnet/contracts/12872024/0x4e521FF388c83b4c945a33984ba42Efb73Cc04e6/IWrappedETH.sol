// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IWrappedETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
}
