// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./ICollectionStruct.sol";
import "./IAffiliateRegistry.sol";

/// @title Collection Interface
/// @author Chain Labs
/// @notice interface to with setup functionality of collection.
interface ICollection is ICollectionStruct {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    /// @notice setup collection with affiliate module
    /// @dev setup all the modules and base collection including affiliate module
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    /// @param _registry address of Simplr Affiliate registry
    /// @param _projectId project ID of Simplr Collection
    function setupWithAffiliate(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens,
        IAffiliateRegistry _registry,
        bytes32 _projectId
    ) external;

    /// @notice setup collection
    /// @dev setup all the modules and base collection
    /// @param _baseCollection struct conatining setup parameters of base collection
    /// @param _presaleable struct conatining setup parameters of presale module
    /// @param _paymentSplitter struct conatining setup parameters of payment splitter module
    /// @param _projectURIProvenance provenance of revealed project URI
    /// @param _royalties struct conatining setup parameters of royalties module
    /// @param _reserveTokens number of tokens to be reserved
    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        RoyaltyInfo memory _royalties,
        uint256 _reserveTokens
    ) external;

    /// @notice updates the collection details (not collection assets)
    /// @dev updates the IPFS CID that points to new collection details
    /// @param _metadata new IPFS CID with updated collection details
    function setMetadata(string memory _metadata) external;
}
