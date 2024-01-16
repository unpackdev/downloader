// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
}