pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT




/**
 * @dev Interface for locking layer artwork project. Implemented interface will allow for functional website.
 */
interface ILockingLayers {

    /** Artwork tier, used for pricing, # layers locked, and gallery benefits */
    enum ArtworkTier {
        ENTHUSIAST,
        COLLECTOR,
        STRATA
    }

    /**
     * @dev Emitted when layer successfully locked.
     */
    event LayerLocked(uint256 artworkId, uint8 layer, uint256 canvasId);

    /**
     * @dev Emit on purchase to know which artwork tier and original owner
     */
    event ArtworkPurchased(uint256 artworkId, uint8 tier);

    /**
     * @dev Returns the current price to buy an artwork in wei.
     */
    function currentPrice(ArtworkTier tier) external view returns (uint256);

    /**
     * @dev Returns the number of artworks issued.
     */
    function totalArtworks() external view returns (uint16);

    /**
     * @dev Returns the total artworks remaining across all tiers.
     */
    function availableArtworks() external view returns (uint16);

    /**
     * @dev Get the price and available artworks for a given tier
     *   - Returns:
     *      - uint256 => PRICE in wei
     *      - uint256 => available artworks
     */
    function getTierPurchaseData(ArtworkTier tier) external view returns (uint256, uint16); 

    /**
     * @dev Get canvasIds for each layer for artwork.
     */
    function getCanvasIds(uint256 artworkId) external view returns (uint16, uint16, uint16, uint16);

    /**
     * @dev The number of blocks remaining until next layer is revealed.
     */
    function blocksUntilNextLayerRevealed() external view returns (uint256);

    /**
     * @dev Checks if an artwork can lock the current layer.
     */
    function canLock(uint256 artworkId) external view returns (bool);

    /**
     * @dev Purchases an artwork.
     *   - Returns the artworkID of purchased work.
     *   - Reverts if insuffiscient funds or no artworks left.
     */
    function purchase(ArtworkTier tier) external payable returns (uint256);

    /**
     * @dev Lock artwork layer.
     *   - Reverts if cannot lock.
     */
    function lockLayer(uint256 artworkId) external; 



}
