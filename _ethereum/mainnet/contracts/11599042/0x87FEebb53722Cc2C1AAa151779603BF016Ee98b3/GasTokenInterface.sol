// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

interface GasTokenInterface {
    function balanceOf(address _who) external view returns (uint256);
    function freeUpTo(uint256 value) external returns (uint256);
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}