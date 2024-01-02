// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./LibDiamond.sol";
import "./IDiamondCut.sol";
import "./LibUtil.sol";


/**
 * @title CATRelayerDiamond
 */
contract CATRelayerDiamond {
	
	event FacetCalled(address indexed facet, bytes4 indexed functionSelector);
	struct DiamondArgs {
		address contractOwner;
 		address wormholeAddress;
		address gasCollector;
		uint8 chainId;
		uint8 finality;
	}
    constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory args) payable {
		LibDiamond.initialize(args.contractOwner, args.wormholeAddress, args.gasCollector, args.chainId, args.finality);
        LibDiamond.diamondCut(_diamondCut, address(0), "");
    }
	
	
	// Find facet for function that is called and execute the
	// function if a facet is found and return any value.
	fallback() external payable {
		LibDiamond.DiamondStorage storage ds;
		bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
		
		// get relayer storage
		assembly {
			ds.slot := position
		}
		
		// get facet from function selector
		address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
		
		if (facet == address(0)) {
			revert LibDiamond.FunctionDoesNotExist();
		}
		
		emit FacetCalled(facet, msg.sig);
		// Execute external function from facet using delegatecall and return any value.
		// solhint-disable-next-line no-inline-assembly
		assembly {
		// copy function selector and any arguments
			calldatacopy(0, 0, calldatasize())
		// execute function call using the facet
			let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
		// get any return value
			returndatacopy(0, 0, returndatasize())
		// return any return value or error back to the caller
			switch result
			case 0 {
				revert(0, returndatasize())
			}
			default {
				return(0, returndatasize())
			}
		}
	}
	
	// Able to receive ether
	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}
}