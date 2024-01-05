// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/******************************************************************************\
* Authors: Nick Mudge (https://twitter.com/mudgen)
* Modified by: 0xShroom (https://github.com/0xshroom)
* Implementation of a diamond.
/******************************************************************************/

import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";


contract Diamond {
    constructor() {
        LibDiamond.setContractOwner(msg.sender);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
      LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

      // Had to add interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId here :( 
      // Cause OpenSea doesn't detect it as ERC721 when called through the DiamondLoupeFacet
      return ds.supportedInterfaces[interfaceId] || interfaceId == type(IERC721).interfaceId
          || interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    // A gas cheap way of adding the DiamondCut facet - can only be called once
    function initDiamondCutFacet(address facet, bytes4 functionSignature) public  {
      LibDiamond.enforceIsContractOwner();

      LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
      require(ds.selectorToFacetAndPosition[functionSignature].facetAddress == address(0), 'Diamond: Diamond was already initiated');

      ds.selectorToFacetAndPosition[functionSignature].functionSelectorPosition = 0;
      ds.facetFunctionSelectors[facet].functionSelectors.push(functionSignature);
      ds.facetFunctionSelectors[facet].facetAddressPosition = 0;
      ds.facetAddresses.push(facet);
      ds.selectorToFacetAndPosition[functionSignature].facetAddress = facet;
  }
}
