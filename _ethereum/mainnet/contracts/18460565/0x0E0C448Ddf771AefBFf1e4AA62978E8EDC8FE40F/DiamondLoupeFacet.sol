// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { LibDiamond } from  "../lib/LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    //get all facet
    function facets() external override view returns (Facet[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address[] memory allFacets=ds.facets;
        Facet[] memory result=new Facet[](allFacets.length);
        uint256 resultIndex=0;
        for(uint256 i=0;i<allFacets.length;i++){
               if(ds.FacetAddressToSelectors[allFacets[i]].length > 0){
                   result[resultIndex].functionSelectors=ds.FacetAddressToSelectors[allFacets[i]];
                   result[resultIndex].facetAddress=allFacets[i]; 
                   resultIndex++;
               }
        }
        assembly {
            mstore(result, resultIndex)
        }
        return result;

    }
    //get selectors  by facet
    function facetFunctionSelectors(address facet) external override view returns (bytes4[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4[] memory result=ds.FacetAddressToSelectors[facet];
        require(result.length > 0,"facet inexistence");
        return result;
    }

    function facetAddresses() external override view returns (address[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address[] memory allFacets=ds.facets;
        address[] memory result=new address[](allFacets.length);
        uint256 resultIndex=0;
        for(uint256 i=0;i<allFacets.length;i++){
             if(ds.FacetAddressToSelectors[allFacets[i]].length > 0){   
                result[resultIndex]= allFacets[i];
                 resultIndex++;
             }
        }
        assembly {
            mstore(result, resultIndex)
        }       
        return result;
    }

    //get facet by selector
    function facetAddress(bytes4 functionSelector) external override view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.SelectorsToFacetAddress[functionSelector];
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}
