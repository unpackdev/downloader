// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC721.sol";

interface IXENFT is IERC721{
    function vmuCount(uint256 tokenId) external view returns (uint256);

    function mintInfo(uint256 tokenId) external view returns (uint256);

    function bulkClaimMintReward(uint256 tokenId, address dest) external;
}