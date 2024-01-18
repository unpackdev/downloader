// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "./ICedarFeatures.sol";
import "./IMulticallable.sol";
import "./ICedarVersioned.sol";
import "./ICedarSFTIssuance.sol";
import "./ISFTLimitSupply.sol";
import "./ISFTSupply.sol";
import "./ICedarUpdateBaseURI.sol";
import "./IERC1155.sol";
import "./IERC2981.sol";
import "./IRoyalty.sol";
import "./ICedarSFTMetadata.sol";
import "./IContractMetadata.sol";
import "./ICedarAgreement.sol";
import "./IPrimarySale.sol";
import "./ICedarLazyMint.sol";
import "./ICedarPausable.sol";

interface ICedarERC1155DropV5 is
    ICedarFeaturesV0,
    ICedarVersionedV2,
    IMulticallableV0,
    IPublicSFTIssuanceV0,
    ISFTSupplyV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC1155V1,
    IERC2981V0,
    IPublicRoyaltyV0,
    IPublicUpdateBaseURIV0,
    IPublicMetadataV0,
    ICedarSFTMetadataV1,
    IPublicAgreementV0,
    IPublicPrimarySaleV1,
    IRestrictedAgreementV0,
    IRestrictedSFTIssuanceV0,
    IRestrictedLazyMintV0,
    IRestrictedPausableV0,
    IRestrictedMetadataV0,
    IRestrictedUpdateBaseURIV0,
    IRestrictedRoyaltyV0,
    IRestrictedPrimarySaleV1,
    IRestrictedSFTLimitSupplyV0
{}
