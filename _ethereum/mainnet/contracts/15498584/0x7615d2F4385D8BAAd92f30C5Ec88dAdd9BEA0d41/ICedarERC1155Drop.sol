// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "./ICedarFeatures.sol";
import "./IMulticallable.sol";
import "./ICedarVersioned.sol";
import "./ICedarSFTIssuance.sol";
import "./ICedarSFTLazyMint.sol";
import "./ICedarUpdateBaseURI.sol";
import "./IERC1155.sol";
import "./IRoyalty.sol";
import "./ICedarSFTMetadata.sol";
import "./IContractMetadata.sol";

interface ICedarERC1155DropV0 is
    ICedarFeaturesV0,
    IMulticallableV0,
    ICedarVersionedV0,
    ICedarSFTIssuanceV0,
    ICedarSFTLazyMintV0,
    ICedarUpdateBaseURIV0,
    IERC1155V0
{

}

/*
    Add ICedarSFTMetadataV0 and ICedarMetadataV0 after opmisation
*/
interface ICedarERC1155DropV1 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarSFTIssuanceV1,
    ICedarSFTLazyMintV0,
    ICedarUpdateBaseURIV0,
    IERC1155V0,
    IRoyaltyV0
{

}
