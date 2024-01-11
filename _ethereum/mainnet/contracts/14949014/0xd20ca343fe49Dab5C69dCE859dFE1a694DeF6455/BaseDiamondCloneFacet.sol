// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondCloneCutFacet.sol";
import "./DiamondCloneLoupeFacet.sol";
import "./BasicAccessControlFacet.sol";
import "./PausableFacet.sol";

contract BaseDiamondCloneFacet is
    DiamondCloneCutFacet,
    DiamondCloneLoupeFacet,
    BasicAccessControlFacet,
    PausableFacet
{}
