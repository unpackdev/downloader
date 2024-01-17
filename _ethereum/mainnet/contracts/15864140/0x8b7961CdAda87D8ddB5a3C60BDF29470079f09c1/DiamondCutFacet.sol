// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Diamond imports
import "./IDiamondCut.sol";
import "./LibDiamond.sol";

/**************************************

    Diamond cut facet

    ------------------------------

    @author Nick Mudge

 **************************************/

contract DiamondCutFacet is IDiamondCut {

    /**************************************

        Cut diamond

        ------------------------------

        @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
        @param _diamondCut Contains the facet addresses and function selectors
        @param _init The address of the contract or facet to execute _calldata
        @param _calldata A function call, including function selector and arguments, that is executed with delegatecall on _init

     **************************************/

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {

        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);

    }
}
