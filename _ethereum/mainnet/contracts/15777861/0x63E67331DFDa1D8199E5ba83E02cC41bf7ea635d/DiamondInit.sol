// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";

import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {    

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init() external {        

    }

}
