// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IBallToken is IERC20 {
    function mint(address to, uint256 amount) external;
}