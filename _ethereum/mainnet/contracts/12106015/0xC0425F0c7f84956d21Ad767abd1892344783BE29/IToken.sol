// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./IERC20.sol";

interface IToken is IERC20{
    function decimals() external view returns (uint);
}