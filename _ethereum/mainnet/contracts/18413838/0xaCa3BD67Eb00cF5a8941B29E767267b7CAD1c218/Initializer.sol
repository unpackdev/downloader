// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// Derived from Nick Mudge's DiamondInit from the reference diamond implementation

import "./IERC721.sol";
import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC165.sol";

import "./Global.sol";
import "./Objects.sol";
import "./Storage.sol";
import "./RayMath.sol";

/// @notice initilizes the kairos protocol
contract Initializer {
    using RayMath for Ray;

    /// @notice initilizes the kairos protocol
    /// @dev specify this method in diamond constructor
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // initializing protocol
        Protocol storage proto = protocolStorage();

        proto.tranche[0] = ONE.div(10).mul(4).div(365 days); // 40% APR
        proto.nbOfTranches = 1;
        proto.auction.priceFactor = ONE.mul(3);
        proto.auction.duration = 3 days;

        // initializing supply position nft collection
        SupplyPosition storage sp = supplyPositionStorage();
        sp.name = "Kairos Supply Position";
        sp.symbol = "KSP";
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
    }
}
