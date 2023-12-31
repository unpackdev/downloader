// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

interface IMWom is IERC20 {
    function deposit(uint256 _amount) external;
    function convert(uint256 amount) external;
}