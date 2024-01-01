// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IDiamond {
    struct FacetCut{
        address  facetAddress;
        bytes4[] addSelectors;
        bytes4[] removeSelectors;   
    }
}