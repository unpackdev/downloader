// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

interface IDERC20 is IERC20 {
    function decimals() external view returns (uint8);
}