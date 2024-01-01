// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IDiamond.sol";

interface IDiamondCut is IDiamond {    
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes memory _calldata
    ) external;    
}
