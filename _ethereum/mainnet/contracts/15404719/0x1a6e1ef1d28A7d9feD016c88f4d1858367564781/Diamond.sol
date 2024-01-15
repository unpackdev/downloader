//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibStorage.sol";
import "./IDiamondCutter.sol";

contract Diamond {

    constructor(address _diamondCutterFacet) {
        // set ownership to deployer
        LibStorage.DiamondStorage storage ds = LibStorage.diamond();
        ds.contractOwner = msg.sender;

        // Add the diamondCut function to the deployed diamondCutter
        bytes4 cutterSelector = IDiamondCutter.diamondCut.selector;
        ds.selectors.push(cutterSelector);
        ds.facets[cutterSelector] = LibStorage.Facet({
            facetAddress: _diamondCutterFacet,
            selectorPosition: 0
        });
    }

    // Search address associated with the selector and delegate execution
    fallback() external payable {
        LibStorage.DiamondStorage storage ds;
        bytes32 position = LibStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facets[msg.sig].facetAddress;
        require(facet != address(0), "Signature not found");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {}

}
