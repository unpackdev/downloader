// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./DiamondLib.sol";
import "./IDiamondCut.sol";

// The DiamondCutFacet contract
//
// This is the very first contract deployed,
// from which everything else is built.
// 
// It handles the adding/removing/updating of contracts (facets).

contract FuckYousEngineer is IDiamondCut {

	/**
		* @notice Add/replace/remove any number of functions and optionally execute
		*         a function with delegatecall
		* @param _diamondCut Contains the facet addresses and function selectors
		* @param _init The address of the contract or facet to execute _calldata
		* @param _calldata A function call, including function selector and arguments
		*                  _calldata is executed with delegatecall on _init
	  */
	function diamondCut(
		FacetCut[] calldata _diamondCut,
		address _init,
		bytes calldata _calldata
	) external override {
		DiamondLib.enforceIsContractOwner();
		DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
		uint256 originalSelectorCount = ds.selectorCount;
		uint256 selectorCount = originalSelectorCount;
		bytes32 selectorSlot;
		// Check if last selector slot is not full
		// "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
		if (selectorCount & 7 > 0) {
			// get last selectorSlot
			// "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
			selectorSlot = ds.selectorSlots[selectorCount >> 3];
		}
		// loop through diamond cut
		for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
			(selectorCount, selectorSlot) = DiamondLib.addReplaceRemoveFacetSelectors(
				selectorCount,
				selectorSlot,
				_diamondCut[facetIndex].facetAddress,
				_diamondCut[facetIndex].action,
				_diamondCut[facetIndex].functionSelectors
			);
		}
		if (selectorCount != originalSelectorCount) {
			ds.selectorCount = uint16(selectorCount);
		}
		// If last selector slot is not full
		// "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
		if (selectorCount & 7 > 0) {
			// "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
			ds.selectorSlots[selectorCount >> 3] = selectorSlot;
		}
		emit DiamondCut(_diamondCut, _init, _calldata);
		DiamondLib.initializeDiamondCut(_init, _calldata);
	}
}
