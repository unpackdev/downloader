// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./OwnershipFacet.sol";
import "./IERC721Receiver.sol";

import "./IAuctionFacet.sol";
import "./IBorrowFacet.sol";
import "./IClaimFacet.sol";
import "./IProtocolFacet.sol";
import "./IRepayFacet.sol";
import "./IAdminFacet.sol";
import "./ISignature.sol";

import "./SupplyPositionFacet.sol";
import "./DiamondERC721.sol";

/* solhint-disable func-visibility */

/// @notice This file is for function selectors getters of facets
/// @dev create a new function for each new facet and update them
///     according to their interface

function loupeFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](5);

    functionSelectors[0] = IDiamondLoupe.facets.selector;
    functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
    functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
    functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
    functionSelectors[4] = IERC165.supportsInterface.selector;

    return functionSelectors;
}

function ownershipFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](2);

    functionSelectors[0] = OwnershipFacet.transferOwnership.selector;
    functionSelectors[1] = OwnershipFacet.owner.selector;

    return functionSelectors;
}

function cutFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](1);

    functionSelectors[0] = IDiamondCut.diamondCut.selector;

    return functionSelectors;
}

function borrowFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](5);

    functionSelectors[0] = IERC721Receiver.onERC721Received.selector;
    functionSelectors[1] = ISignature.offerDigest.selector;
    functionSelectors[2] = ISignature.apiCoSignedPayloadDigest.selector;
    functionSelectors[3] = IBorrowFacet.borrow.selector;
    functionSelectors[4] = IBorrowFacet.transferBorrowerRights.selector;

    return functionSelectors;
}

function supplyPositionFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](14);

    functionSelectors[0] = IERC721.balanceOf.selector;
    functionSelectors[1] = IERC721.ownerOf.selector;
    functionSelectors[2] = DiamondERC721.name.selector;
    functionSelectors[3] = DiamondERC721.symbol.selector;
    functionSelectors[4] = IERC721.approve.selector;
    functionSelectors[5] = IERC721.getApproved.selector;
    functionSelectors[6] = IERC721.setApprovalForAll.selector;
    functionSelectors[7] = IERC721.isApprovedForAll.selector;
    functionSelectors[8] = IERC721.transferFrom.selector;
    functionSelectors[9] = getSelector("safeTransferFrom(address,address,uint256)");
    functionSelectors[10] = getSelector("safeTransferFrom(address,address,uint256,bytes)");
    functionSelectors[11] = SupplyPositionFacet.position.selector;
    functionSelectors[12] = SupplyPositionFacet.totalSupply.selector;
    functionSelectors[13] = SupplyPositionFacet.tokenURI.selector;

    return functionSelectors;
}

/// @notice protocol facet function selectors
function protoFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](5);

    functionSelectors[0] = IProtocolFacet.getRateOfTranche.selector;
    functionSelectors[1] = IProtocolFacet.getParameters.selector;
    functionSelectors[2] = IProtocolFacet.getLoan.selector;
    functionSelectors[3] = IProtocolFacet.getMinOfferCostAndBorrowableAmount.selector;
    functionSelectors[4] = IProtocolFacet.getFeeRateForAsset.selector;

    return functionSelectors;
}

function repayFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](2);

    functionSelectors[0] = IRepayFacet.repay.selector;
    functionSelectors[1] = IRepayFacet.toRepay.selector;

    return functionSelectors;
}

function auctionFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](2);

    functionSelectors[0] = IAuctionFacet.buy.selector;
    functionSelectors[1] = IAuctionFacet.price.selector;

    return functionSelectors;
}

function claimFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](2);

    functionSelectors[0] = IClaimFacet.claim.selector;
    functionSelectors[1] = IClaimFacet.claimAsBorrower.selector;

    return functionSelectors;
}

function adminFS() pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](8);

    functionSelectors[0] = IAdminFacet.setAuctionDuration.selector;
    functionSelectors[1] = IAdminFacet.setAuctionPriceFactor.selector;
    functionSelectors[2] = IAdminFacet.createTranche.selector;
    functionSelectors[3] = IAdminFacet.setMinOfferCost.selector;
    functionSelectors[4] = IAdminFacet.setBorrowAmountPerOfferLowerBound.selector;
    functionSelectors[5] = IAdminFacet.setBaseMetadataUri.selector;
    functionSelectors[6] = IAdminFacet.setApiAddress.selector;
    functionSelectors[7] = IAdminFacet.setFeeRateForAsset.selector;

    return functionSelectors;
}

function getSelector(string memory _func) pure returns (bytes4) {
    return bytes4(keccak256(bytes(_func)));
}

function copyNSelectors(bytes4[] memory initialSelectors, uint256 numberToCopy) pure returns (bytes4[] memory) {
    bytes4[] memory functionSelectors = new bytes4[](numberToCopy);

    for (uint256 i = 0; i < numberToCopy; i++) {
        functionSelectors[i] = initialSelectors[i];
    }

    return functionSelectors;
}
