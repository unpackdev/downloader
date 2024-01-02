// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWstETH is IERC20 {
    function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256 stETHAmount);

    function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256 wstETHAmount);

    function stEthPerToken() external view returns (uint256 stETHAmount);

    function tokensPerStEth() external view returns (uint256 wstETHAmount);

    function wrap(uint256 stETHAmount) external returns (uint256 wstETHAmount);

    function unwrap(uint256 wstETHAmount) external returns (uint256 stETHAmount);
}
