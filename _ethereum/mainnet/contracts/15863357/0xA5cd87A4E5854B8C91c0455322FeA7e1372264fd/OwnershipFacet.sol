// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Diamond imports
import "./LibDiamond.sol";
import "./IERC173.sol";

/**************************************

    Ownership facet

 **************************************/

contract OwnershipFacet is IERC173 {

    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

}
