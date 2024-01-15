// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*************************************************************\
Forked from https://github.com/mudgen/diamond
/*************************************************************/

interface IDiamondCutter {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        FacetCutAction action;
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}
