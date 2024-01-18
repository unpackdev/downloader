// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "./ICedarFeatures.sol";
import "./IMulticallable.sol";
import "./ICedarVersioned.sol";
import "./ICedarNFTIssuance.sol";
import "./INFTLimitSupply.sol";
import "./ICedarAgreement.sol";
import "./INFTSupply.sol";
import "./ICedarLazyMint.sol";
import "./IERC721.sol";
import "./IERC2981.sol";
import "./IRoyalty.sol";
import "./ICedarUpdateBaseURI.sol";
import "./ICedarNFTMetadata.sol";
import "./IContractMetadata.sol";
import "./IPrimarySale.sol";
import "./ICedarPausable.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0

interface ICedarERC721DropV7 is
    ICedarFeaturesV0,
    ICedarVersionedV2,
    IMulticallableV0,
    IPublicNFTIssuanceV0,
    INFTSupplyV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC721V1,
    IERC2981V0,
    IPublicRoyaltyV0,
    IPublicUpdateBaseURIV0,
    IPublicMetadataV0,
    ICedarNFTMetadataV1,
    IPublicAgreementV0,
    IPublicPrimarySaleV1,
    IRestrictedAgreementV0,
    IRestrictedNFTIssuanceV0,
    IRestrictedLazyMintV0,
    IRestrictedPausableV0,
    IRestrictedMetadataV0,
    IRestrictedUpdateBaseURIV0,
    IRestrictedRoyaltyV0,
    IRestrictedPrimarySaleV1,
    IRestrictedNFTLimitSupplyV0
{

}
