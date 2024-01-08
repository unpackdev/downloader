// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./DiamondLib.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC165.sol";

// The DiamondInit contract
//
// This contract initializes all the facets,
// providing them with common state variables (Diamond Storage)

contract FuckYousSurveyor {
	// You can add parameters to this function in order to pass in 
	// data to set your own state variables
	function init() external {
		// adding ERC165 data
		DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
		ds.supportedInterfaces[type(IERC165).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
		ds.supportedInterfaces[type(IERC173).interfaceId] = true;

		// add your own state variables 
		// EIP-2535 specifies that the `diamondCut` function takes two optional 
		// arguments: address _init and bytes calldata _calldata
		// These arguments are used to execute an arbitrary function using delegatecall
		// in order to set state variables in the diamond during deployment or an upgrade
		// More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
	}
}