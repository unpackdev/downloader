// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Diamond imports
import "./LibDiamond.sol";

// Local imports
import "./IRaiseFacet.sol";
import "./IMilestoneFacet.sol";
import "./INonceFacet.sol";
import "./IEscrowFacet.sol";

/**************************************

    Fundraising migration v1.1

    ------------------------------

    Diamond migration looks like this:
    - deploy initializer
    - deploy new facets
    - perform cut with facets and initializer

 **************************************/

/// @dev Migration initializer for v1.1 of fundraising.
contract FundraisingMigrate110 {
    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev External init function for a delegate call.
    function init() external {
        // interfaces
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IRaiseFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IMilestoneFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IEscrowFacet).interfaceId] = true;
        ds.supportedInterfaces[type(INonceFacet).interfaceId] = true;
    }
}
