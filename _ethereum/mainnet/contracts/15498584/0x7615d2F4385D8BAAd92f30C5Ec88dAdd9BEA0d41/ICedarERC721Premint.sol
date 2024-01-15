// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import "./ICedarFeatures.sol";
import "./ICedarIssuer.sol";
import "./ICedarClaimable.sol";
import "./ICedarOrderFiller.sol";
import "./ICedarNativePayable.sol";
import "./ICedarERC20Payable.sol";
import "./IMulticallable.sol";
import "./ICedarIssuance.sol";
import "./ICedarVersioned.sol";
import "./ICedarPremint.sol";
import "./ICedarAgreement.sol";
import "./ICedarUpgradeBaseURI.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0
interface ICedarERC721PremintV0 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    ICedarPremintV0,
    ICedarAgreementV0,
    IMulticallableV0
{
}

interface ICedarERC721PremintV1 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    ICedarPremintV0,
    ICedarAgreementV0,
    IMulticallableV0,
    ICedarUpgradeBaseURIV0
{
}