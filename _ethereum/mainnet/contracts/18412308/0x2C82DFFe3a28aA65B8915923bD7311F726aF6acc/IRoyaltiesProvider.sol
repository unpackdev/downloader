// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IRoyaltiesProvider {
    function calculateRoyaltiesAndGetRecipient(
        address nftContract,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}
