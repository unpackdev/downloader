// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "./ICedarFeatures.sol";
import "./IMulticallable.sol";
import "./ICedarVersioned.sol";
import "./ICedarNFTIssuance.sol";
import "./ICedarAgreement.sol";
import "./ICedarLazyMint.sol";
import "./IERC721.sol";
import "./IRoyalty.sol";
import "./ICedarUpdateBaseURI.sol";
import "./ICedarNFTMetadata.sol";
import "./IContractMetadata.sol";
import "./IPrimarySale.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0

interface ICedarERC721DropV5 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarAgreementV0,
    ICedarNFTIssuanceV2,
    ICedarLazyMintV0,
    IERC721V0,
    IRoyaltyV0,
    ICedarUpdateBaseURIV0,
    ICedarNFTMetadataV1,
    ICedarMetadataV1,
    IPrimarySaleV0
{

}
