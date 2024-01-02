// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
