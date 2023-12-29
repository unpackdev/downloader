// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IScales is IERC20 {
    function spend(address, uint256) external;
    function credit(address, uint256) external;
}