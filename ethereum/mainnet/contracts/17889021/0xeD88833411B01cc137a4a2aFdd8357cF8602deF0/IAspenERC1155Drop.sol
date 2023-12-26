// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "./IAspenFeatures.sol";
import "./IMulticallable.sol";
import "./IAspenVersioned.sol";
import "./ICedarSFTIssuance.sol";
import "./ISFTLimitSupply.sol";
import "./ISFTSupply.sol";
import "./ISFTClaimCount.sol";
import "./IUpdateBaseURI.sol";
import "./IERC1155.sol";
import "./IERC2981.sol";
import "./IERC4906.sol";
import "./IRoyalty.sol";
import "./ISFTMetadata.sol";
import "./IContractMetadata.sol";
import "./IAgreement.sol";
import "./IPrimarySale.sol";
import "./ILazyMint.sol";
import "./IPausable.sol";
import "./IOwnable.sol";
import "./IPlatformFee.sol";

interface IAspenERC1155DropV3 is
    IAspenFeaturesV1,
    IAspenVersionedV2,
    IMulticallableV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC1155V4,
    IERC2981V0,
    IRestrictedERC4906V0,
    // NOTE: keep this standard interfaces around to generate supportsInterface ˆˆ
    // Supply
    IDelegatedSFTSupplyV2,
    IRestrictedSFTLimitSupplyV1,
    // Issuance
    IPublicSFTIssuanceV5,
    IDelegatedSFTIssuanceV1,
    IRestrictedSFTIssuanceV5,
    // Royalties
    IDelegatedRoyaltyV1,
    IRestrictedRoyaltyV1,
    // BaseUri
    IDelegatedUpdateBaseURIV1,
    IRestrictedUpdateBaseURIV1,
    // Metadata
    IDelegatedMetadataV0,
    IRestrictedMetadataV2,
    IAspenSFTMetadataV1,
    // Ownable
    IPublicOwnableV1,
    // Pausable
    IDelegatedPausableV0,
    IRestrictedPausableV1,
    // Agreement
    IPublicAgreementV2,
    IDelegatedAgreementV1,
    IRestrictedAgreementV3,
    // Primary Sale
    IDelegatedPrimarySaleV0,
    IRestrictedPrimarySaleV2,
    IRestrictedSFTPrimarySaleV0,
    // Operator Filterer
    IRestrictedOperatorFiltererV0,
    IPublicOperatorFilterToggleV1,
    IRestrictedOperatorFilterToggleV0,
    // Delegated only
    IDelegatedPlatformFeeV0,
    // Restricted Only
    IRestrictedLazyMintV1,
    IRestrictedSFTClaimCountV0
{}
