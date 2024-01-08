// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibArtwork.sol";
import "./ITRLabCore.sol";

/// @title Interface for NFT buy-now in a fixed price.
/// @author Joe
/// @notice This is the interface for fixed price NFT buy-now.
interface IBuyNow {
    /// @notice This event emits when a new artwork has been put on sale.
    /// @param artworkId uint256 the id of the on sale artwork.
    /// @param onSaleInfo the on sale object.
    event ArtworkOnSale(uint256 indexed artworkId, LibArtwork.ArtworkOnSaleInfo onSaleInfo);

    /// @dev Sets the trlab nft core contract address.
    /// @param  _trlabCore address the address of the trlab core contract.
    function setTRLabCore(ITRLabCore _trlabCore) external;

    /// @dev Sets the trlab wallet to receive NFT sale income.
    /// @param  _trlabWallet address the address of the trlab wallet.
    function setTRLabWallet(address _trlabWallet) external;

    /// @dev setup an artwork for sale
    /// @param  _artworkId uint256 the address of the trlab wallet.
    /// @param  _onSaleInfo the ArtworkOnSaleInfo object.
    function putOnSale(uint256 _artworkId, LibArtwork.ArtworkOnSaleInfo memory _onSaleInfo) external;

    /// @notice buy one NFT token of specific artwork. Needs a proper signature of allowed signer to verify purchase.
    /// @param  _artworkId uint256 the id of the artwork to buy.
    /// @param  v uint8 v of the signature
    /// @param  r bytes32 r of the signature
    /// @param  s bytes32 s of the signature
    function buyNow(
        uint256 _artworkId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
