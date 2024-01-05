// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ITiles is IERC20 {
    function spend(address account, uint256 amount) external;
}