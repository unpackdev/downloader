// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint256);
}
