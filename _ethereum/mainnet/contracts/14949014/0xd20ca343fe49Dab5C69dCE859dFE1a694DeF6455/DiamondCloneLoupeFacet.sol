// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondCloneLib.sol";
import "./IDiamondLoupe.sol";
import "./IERC165.sol";
import "./DiamondSaw.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

contract DiamondCloneLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    //  Finds the subset of all facets used in this facet clone
    function facets() external view override returns (Facet[] memory facets_) {
        facets_ = DiamondCloneLib.facets();
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib.diamondCloneStorage();
        facetFunctionSelectors_ = DiamondSaw(ds.diamondSawAddress).functionSelectorsForFacetAddress(_facet);
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        facetAddresses_ = DiamondCloneLib.facetAddresses();
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib.diamondCloneStorage();
        facetAddress_ = DiamondSaw(ds.diamondSawAddress).facetAddressForSelector(_functionSelector);
    }

    // This implements ERC-165.
    // DiamondSaw maintains a map of which facet addresses implement which interfaces
    // All the clone has to do is query the facet address and check if the clone implements it
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        DiamondCloneLib.DiamondCloneStorage storage ds = DiamondCloneLib.diamondCloneStorage();
        address facetAddressForInterface = DiamondSaw(ds.diamondSawAddress).facetAddressForInterface(_interfaceId);

        return ds.facetAddresses[facetAddressForInterface];
    }
}
