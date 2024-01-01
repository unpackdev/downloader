// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IOriginsNFT
 * @dev Interface for Origins & Ancestries: Genesis Collection NFT contract
 * @author Amberfi
 */
interface IOriginsNFT {
    /**
     * @notice Mints a new NFT with a specific ID to a designated address.
     *
     * @dev This function is primarily called by the MarketManager to facilitate the minting process when a user purchases an NFT.
     * External contracts or accounts that call this function should have the necessary permissions.
     *
     * @param to_ (address) - The address to which the NFT will be minted.
     * @param tokenId_ (uint256) - The unique ID of the NFT to be minted.
     */
    function mint(address to_, uint256 tokenId_) external;
}
