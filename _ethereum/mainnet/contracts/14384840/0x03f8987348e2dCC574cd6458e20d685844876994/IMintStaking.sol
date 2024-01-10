// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMintStaking {
    function stakeFrom(address from, uint256 poolId, uint256 tokenId) external;
    function batchStakeFrom(address from, uint256 poolId, uint256[] calldata tokenIds) external;
}