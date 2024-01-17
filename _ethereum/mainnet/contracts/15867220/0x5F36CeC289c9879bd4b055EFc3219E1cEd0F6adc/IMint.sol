// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IMint {
    function mint(address account, uint256 amount) external;
}
