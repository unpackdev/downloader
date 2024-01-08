

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";


interface IBXH is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}