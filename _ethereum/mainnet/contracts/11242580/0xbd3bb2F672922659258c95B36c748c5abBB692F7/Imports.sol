// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./DiamondCutFacet.sol";
import "./DiamondLoupeFacet.sol";
import "./OwnershipFacet.sol";


// Get the compiler and typechain to pick up these facets
contract Imports {
    DiamondCutFacet public diamondCutFacet;
    DiamondLoupeFacet public diamondLoupeFacet;
    OwnershipFacet public ownershipFacet;
}