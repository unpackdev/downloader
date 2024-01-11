// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

interface IWStEth {
    function wrap(uint256 _stETHAmount) external;

    function unwrap(uint256 _wstETHAmount) external;

    function balanceOf(address) external view returns (uint256);
}
