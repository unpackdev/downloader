// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IJournal {
    function mint(address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
