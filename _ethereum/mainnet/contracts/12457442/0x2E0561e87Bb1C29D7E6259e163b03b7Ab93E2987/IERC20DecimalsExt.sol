// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20.sol";

interface IERC20DecimalsExt is IERC20 {
    function decimals() external view returns(uint8);
}