// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

interface IFoundation {
    function buyV2(
        IERC721 nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        address referrer
    ) external payable;
}
