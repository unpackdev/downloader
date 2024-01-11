// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeERC20.sol";

/// @title Interface for CHI gas token
interface IChi is IERC20 {
    function mint(uint256 value) external;

    function free(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256 freed);
}
