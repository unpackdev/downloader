// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SeenConstants.sol";
import "./IDiamondCut.sol";
import "./DiamondLib.sol";
import "./JewelerLib.sol";

/**
 * @title DiamondCutFacet
 *
 * @notice DiamondCut facet based on Nick Mudge's gas-optimized diamond-2 reference.
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * @author Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract DiamondCutFacet is SeenConstants, IDiamondCut {

    /**
     * @notice Cut facets of the Diamond
     *
     * Add/replace/remove any number of function selectors
     *
     * If populated, _calldata is executed with delegatecall on _init
     *
     * Reverts if caller does not have UPGRADER role
     *
     * @param _facetCuts Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata)
    external
    override
    {
        // Get the diamond storage slot
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Ensure the caller has the UPGRADER role
        require(ds.accessController.hasRole(UPGRADER, msg.sender), "Caller must have UPGRADER role");

        // Make the cuts
        JewelerLib.diamondCut(_facetCuts, _init, _calldata);

    }
}
