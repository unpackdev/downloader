// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}
