// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;
import "./IERC20.sol";

// @title Wrapped token ERC20 interface
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}
