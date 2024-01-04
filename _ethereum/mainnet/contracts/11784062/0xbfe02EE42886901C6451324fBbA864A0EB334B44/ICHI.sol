// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IERC20.sol";

interface ICHI is IERC20 {
    function freeFromUpTo(address _addr, uint256 _amount) external returns (uint256);
}