// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./LibDiamond.sol";

abstract contract BFacetOwner {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}
