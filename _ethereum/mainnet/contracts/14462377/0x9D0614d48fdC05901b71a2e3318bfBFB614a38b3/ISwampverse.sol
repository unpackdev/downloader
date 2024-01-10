// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISwampverse {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function setApprovalForAll(address user, bool approved) external;
}