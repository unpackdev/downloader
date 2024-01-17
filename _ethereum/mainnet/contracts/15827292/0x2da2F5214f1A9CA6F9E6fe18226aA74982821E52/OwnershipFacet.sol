// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LibDiamond.sol";
import "./BaseFacet.sol";

contract OwnershipFacet is BaseFacet, IERC173 {
    function transferOwnership(address _newOwner) external override onlyOwner {
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}