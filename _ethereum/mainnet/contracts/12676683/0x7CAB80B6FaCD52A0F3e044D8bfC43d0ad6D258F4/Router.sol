// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC165.sol";
import "./LibDiamond.sol";

contract Router {
    constructor(IDiamondCut.FacetCut[] memory _diamondCut) payable {
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
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
}
