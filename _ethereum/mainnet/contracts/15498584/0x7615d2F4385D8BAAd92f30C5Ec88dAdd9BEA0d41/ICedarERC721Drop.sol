// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "./ICedarFeatures.sol";
import "./IMulticallable.sol";
import "./ICedarVersioned.sol";
import "./ICedarNFTIssuance.sol";
import "./ICedarAgreement.sol";
import "./ICedarNFTLazyMint.sol";
import "./IERC721.sol";
import "./IRoyalty.sol";
import "./ICedarUpdateBaseURI.sol";
import "./ICedarNFTMetadata.sol";
import "./IContractMetadata.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0
interface ICedarERC721DropV0 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    ICedarNFTIssuanceV0,
    ICedarNFTLazyMintV0,
    IMulticallableV0,
    IERC721V0
{
}

interface ICedarERC721DropV1 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarAgreementV0,
    ICedarNFTIssuanceV1,
    ICedarNFTLazyMintV0,
    IERC721V0,
    IRoyaltyV0
{}

interface ICedarERC721DropV2 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarAgreementV0,
    ICedarNFTIssuanceV1,
    ICedarNFTLazyMintV1,
    IERC721V0,
    IRoyaltyV0,
    ICedarUpdateBaseURIV0,
    ICedarNFTMetadataV0,
    ICedarMetadataV0
{}

interface ICedarERC721DropV3 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarAgreementV0,
    ICedarNFTIssuanceV1,
    ICedarNFTLazyMintV1,
    IERC721V0,
    IRoyaltyV0,
    ICedarUpdateBaseURIV0,
    ICedarNFTMetadataV1,
    ICedarMetadataV0
{}
