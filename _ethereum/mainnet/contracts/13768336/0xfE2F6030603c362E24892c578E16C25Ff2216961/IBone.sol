// SPDX-License-Identifier: MIT
// $BONE Interface

pragma solidity >= 0.7.0 <0.9.0;

import "./IERC20.sol";

interface IBone is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}