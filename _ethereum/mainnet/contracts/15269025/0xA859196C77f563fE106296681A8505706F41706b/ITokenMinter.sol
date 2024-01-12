// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenMinter {
    function mint(address receiver, uint256 amount) external;
}