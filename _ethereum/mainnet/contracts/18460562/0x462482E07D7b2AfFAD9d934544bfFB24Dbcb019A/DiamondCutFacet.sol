// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./IDiamondCut.sol";
import "./LibDiamond.sol";
contract DiamondCutFacet is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
