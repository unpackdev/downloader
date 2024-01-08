// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISwishToken {
    function mint(address user, uint256 cvxAmount) external;
}
