// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.1.0) (lib/Marketplace.sol)

pragma solidity ^0.8.4;

import "./Ownership.sol";

/**
 * @title Arttaca Marketplace library.
 */
library LazyMint1155 {
    struct TokenData {
        uint id;
        string URI;
        uint quantity;
        Ownership.Royalties royalties;
        uint expTimestamp;
        bytes signature;
    }

    struct SaleData {
        uint listingId;
        address lister;
        address buyer;
        uint listingQuantity;
        uint buyingQuantity;
        uint price;
        uint listingExpTimestamp;
        uint nodeExpTimestamp;
        bytes listingSignature;
        bytes nodeSignature;
    }

    bytes32 public constant MINT_TYPEHASH = keccak256("Minting(address collectionAddress,uint id,uint quantity,string tokenURI,Split[] splits,uint96 percentage,uint expTimestamp)Split(address account,uint96 shares)");

    function hashMint(address collectionAddress, TokenData memory _tokenData) internal pure returns (bytes32) {
        bytes32[] memory splitBytes = new bytes32[](_tokenData.royalties.splits.length);

        for (uint i = 0; i < _tokenData.royalties.splits.length; ++i) {
            splitBytes[i] = Ownership.hash(_tokenData.royalties.splits[i]);
        }

        return keccak256(
            abi.encode(
                MINT_TYPEHASH,
                collectionAddress,
                _tokenData.id,
                _tokenData.quantity,
                keccak256(bytes(_tokenData.URI)),
                keccak256(abi.encodePacked(splitBytes)),
                _tokenData.royalties.percentage,
                _tokenData.expTimestamp
            )
        );
    }

    bytes32 public constant SELLER_LISTING_TYPEHASH = keccak256("SellerListing(uint listingId,address lister,address collectionAddress,uint id,uint quantity,uint price,uint expTimestamp)");

    function hashSellerListing(address collectionAddress, TokenData memory _tokenData, SaleData memory _saleData) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                SELLER_LISTING_TYPEHASH,
                _saleData.listingId,
                _saleData.lister,
                collectionAddress,
                _tokenData.id,
                _saleData.listingQuantity,
                _saleData.price,
                _saleData.listingExpTimestamp
            )
        );
    }

    bytes32 public constant NODE_LISTING_TYPEHASH = keccak256("NodeListing(uint listingId,address lister,address buyer,address collectionAddress,uint id,uint listingQuantity,uint buyingQuantity,uint price,uint expTimestamp)");

    function hashNodeListing(address collectionAddress, TokenData memory _tokenData, SaleData memory _saleData) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                NODE_LISTING_TYPEHASH,
                _saleData.listingId,
                _saleData.lister,
                _saleData.buyer,
                collectionAddress,
                _tokenData.id,
                _saleData.listingQuantity,
                _saleData.buyingQuantity,
                _saleData.price,
                _saleData.nodeExpTimestamp
            )
        );
    }
}
