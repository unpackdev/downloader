// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITokenManager {
    function deposit(
        address from,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external returns (uint256);

    function withdraw(
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external returns (uint256);
}