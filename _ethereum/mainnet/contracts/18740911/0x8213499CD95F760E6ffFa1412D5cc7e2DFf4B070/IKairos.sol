// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";

import "./IAdminFacet.sol";
import "./IAuctionFacet.sol";
import "./IBorrowFacet.sol";
import "./IClaimFacet.sol";
import "./IOwnershipFacet.sol";
import "./IProtocolFacet.sol";
import "./IRepayFacet.sol";
import "./ISupplyPositionFacet.sol";

/* solhint-disable-next-line no-empty-blocks */
interface IKairos is
    IDiamondLoupe,
    IDiamondCut,
    IAdminFacet,
    IAuctionFacet,
    IBorrowFacet,
    IClaimFacet,
    IOwnershipFacet,
    IProtocolFacet,
    IRepayFacet,
    ISupplyPositionFacet
{

}
