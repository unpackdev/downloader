// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";

interface WETHInterface {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
    function withdraw(uint wad) external;
}

abstract contract WETH is WETHInterface {}