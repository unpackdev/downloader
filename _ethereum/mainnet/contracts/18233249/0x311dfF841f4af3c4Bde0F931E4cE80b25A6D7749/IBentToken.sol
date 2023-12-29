// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IBentToken is IERC20 {
    function mint(address user, uint256 cvxAmount) external;
}
