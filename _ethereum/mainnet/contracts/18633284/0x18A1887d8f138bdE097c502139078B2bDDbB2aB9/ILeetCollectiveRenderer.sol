// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ILeetCollectiveRenderer {
    function render(
        address owner,
        string memory name,
        string memory bio,
        string memory color,
        string memory role,
        uint256 skull
    ) external view returns (string memory metadata);
}
