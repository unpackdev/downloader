// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArrayAirdropper {
    function airdrop(address[] memory addresses, uint256 amount) external returns (uint256);
}
