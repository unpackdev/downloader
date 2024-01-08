// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
}
