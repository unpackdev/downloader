// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function withdraw(uint256 wad) external;
}
