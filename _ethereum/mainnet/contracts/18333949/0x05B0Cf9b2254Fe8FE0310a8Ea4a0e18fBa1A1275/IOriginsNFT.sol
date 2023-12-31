// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IOriginsNFT
 * @dev Interface for OriginsNFT contract
 * @author Amberfi
 */
interface IOriginsNFT {
    /**
     * @dev Mint NFT with ID `tokenId_` (called by MarketManager)
     * @param to_ (address) Mint to address
     * @param tokenId_ (uint256) Token ID to mint
     */
    function mint(address to_, uint256 tokenId_) external;
}
