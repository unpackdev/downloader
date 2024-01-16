// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";
import "./IERC173.sol";
import "./AccessControl.sol";

// import "./Ownable.sol";

contract OwnershipFacet is IERC173, AccessControl {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        return LibDiamond.contractOwner();
    }

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32) {
        return s.DEFAULT_ADMIN_ROLE;
    }

    function OWNER_ROLE() external view returns (bytes32) {
        return s.OWNER_ROLE;
    }
}
