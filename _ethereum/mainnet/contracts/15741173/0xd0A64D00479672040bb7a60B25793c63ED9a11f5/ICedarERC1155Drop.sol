// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "./ICedarFeatures.sol";
import "./IMulticallable.sol";
import "./ICedarVersioned.sol";
import "./ICedarSFTIssuance.sol";
import "./ICedarLazyMint.sol";
import "./ICedarUpdateBaseURI.sol";
import "./IERC1155.sol";
import "./IRoyalty.sol";
import "./ICedarSFTMetadata.sol";
import "./IContractMetadata.sol";
import "./ICedarAgreement.sol";
import "./IPrimarySale.sol";

interface ICedarERC1155DropV3 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarSFTIssuanceV1,
    ICedarLazyMintV0,
    ICedarUpdateBaseURIV0,
    IERC1155SupplyV0,
    IRoyaltyV0,
    ICedarMetadataV1,
    ICedarAgreementV0,
    IPrimarySaleV0
{}
