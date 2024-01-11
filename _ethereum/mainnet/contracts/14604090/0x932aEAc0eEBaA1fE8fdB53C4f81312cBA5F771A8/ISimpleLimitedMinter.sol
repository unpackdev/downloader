// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ISimpleLimitedMinter {
    function tryMint(address to) external returns (bool minted, uint256 tokenId);
}
